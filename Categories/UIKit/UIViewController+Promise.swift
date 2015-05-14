import Foundation.NSError
import PromiseKit
import UIKit

/**
 To import this `UIViewController` category:

    use_frameworks!
    pod "PromiseKit/UIKit"

 Or `UIKit` is one of the categories imported by the umbrella pod:

    use_frameworks!
    pod "PromiseKit"

 And then in your sources:

    import PromiseKit
*/
extension UIViewController {
    public func promiseViewController<T>(vc: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) -> Promise<T> {

        let p: Promise<T> = promise(vc)
        if p.pending {
            presentViewController(vc, animated: animated, completion: completion)
            p.finally {
                self.dismissViewControllerAnimated(animated, completion: nil)
            }
        }

        return p
    }
    
    public func promiseViewController<T>(nc: UINavigationController, animated: Bool = true, completion:(()->Void)? = nil) -> Promise<T> {
        if let vc = nc.viewControllers.first as? UIViewController {
            let p: Promise<T> = promise(vc)
            if p.pending {
                presentViewController(nc, animated: animated, completion: completion)
                p.finally {
                    self.dismissViewControllerAnimated(animated, completion: nil)
                }
            }
            return p
        } else {
            return Promise(error: "Cannot promise an empty UINavigationController")
        }
    }

    public func promiseViewController(vc: UIImagePickerController, animated: Bool = true, completion: (() -> Void)? = nil) -> Promise<UIImage> {
        let proxy = UIImagePickerControllerProxy()
        vc.delegate = proxy
        vc.mediaTypes = ["public.image"]  // this promise can only resolve with a UIImage
        presentViewController(vc, animated: animated, completion: completion)
        return proxy.promise.then(on: zalgo) { info -> Promise<UIImage> in
            if let img = info[UIImagePickerControllerEditedImage] as? UIImage {
                return Promise(img)
            }
            if let img = info[UIImagePickerControllerOriginalImage] as? UIImage {
                return Promise(img)
            }
            return Promise(error: "No image was found", code: PMKUnexpectedError)
        }.finally(on: zalgo) {
            self.dismissViewControllerAnimated(animated, completion: nil)
        }
    }
}

@objc public protocol Promisable {
    /**
    Provide a promise for promiseViewController here.

    The resulting property must be annotated with @objc.

    Obviously return a Promise. There is an issue with generics and Swift and
    protocols currently so we couldn't specify that.
    */
    var promise: AnyObject! { get }
}

private func promise<T>(vc: UIViewController) -> Promise<T> {
    if !vc.conformsToProtocol(Promisable) {
        return Promise(error: "The provided UIViewController does not conform to the Promisable protocol.", code: PMKInvalidUsageError)
    } else if let promise = vc.valueForKeyPath("promise") as? Promise<T> {
        return promise
    } else if let promise: AnyObject = vc.valueForKeyPath("promise") {
        return Promise(error: "The provided UIViewController’s promise has unexpected type specialization.", code: PMKInvalidUsageError)
    } else {
        return Promise(error: "The provided UIViewController’s promise property returned nil", code: PMKInvalidUsageError)
    }
}


// internal scope because used by ALAssetsLibrary extension
@objc class UIImagePickerControllerProxy: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let (promise, fulfill, reject) = Promise<[NSObject : AnyObject]>.defer()
    var retainCycle: AnyObject?

    required override init() {
        super.init()
        retainCycle = self
    }

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        fulfill(info)
        retainCycle = nil
    }

    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        reject(NSError.cancelledError())
        retainCycle = nil
    }
}
