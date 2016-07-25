import Foundation.NSError
import UIKit
#if !COCOAPODS
import PromiseKit
#endif

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

    public enum Error: ErrorType {
        case NavigationControllerEmpty
        case NoImageFound
        case NotPromisable
        case NotGenericallyPromisable
        case NilPromisable
    }

    public enum FulfillmentType {
        case OnceDisappeared
        case BeforeDismissal
    }

    public struct AnimationOptions: OptionSetType {
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        public let rawValue: Int

        static let None      = AnimationOptions(rawValue: 0)
        static let Appear    = AnimationOptions(rawValue: 1 << 0)
        static let Disappear = AnimationOptions(rawValue: 1 << 1)
    }

    @available(*, deprecated=3.4, renamed="promiseViewController(_:animate:fulfills:completion:)")
    public func promiseViewController<T>(vc: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) -> Promise<T> {
        return promiseViewController(vc, animate: [.Appear, .Disappear], completion: completion)
    }

    public func promiseViewController<T>(vc: UIViewController, animate animationOptions: AnimationOptions = [.Appear, .Disappear], fulfills: FulfillmentType = .OnceDisappeared, completion: (() -> Void)? = nil) -> Promise<T> {

        let pvc: UIViewController

        switch vc {
        case let nc as UINavigationController:
            guard let vc = nc.viewControllers.first else { return Promise(error: Error.NavigationControllerEmpty) }
            pvc = vc
        default:
            pvc = vc
        }

        let promise: Promise<T>

        if !pvc.conformsToProtocol(Promisable) {
            promise = Promise(error: UIViewController.Error.NotPromisable)
        } else if let p = pvc.valueForKeyPath("promise") as? Promise<T> {
            promise = p
        } else if let _: AnyObject = pvc.valueForKeyPath("promise") {
            promise = Promise(error: UIViewController.Error.NotGenericallyPromisable)
        } else {
            promise = Promise(error: UIViewController.Error.NilPromisable)
        }

        if promise.pending {
            presentViewController(vc, animated: animationOptions.contains(.Appear), completion: completion)
            promise.always {
                vc.presentingViewController?.dismissViewControllerAnimated(animationOptions.contains(.Disappear), completion: nil)
            }
        }

        return promise
    }

    public func promiseViewController(vc: UIImagePickerController, animated: Bool = true, completion: (() -> Void)? = nil) -> Promise<UIImage> {
        let proxy = UIImagePickerControllerProxy()
        vc.delegate = proxy
        vc.mediaTypes = ["public.image"]  // this promise can only resolve with a UIImage
        presentViewController(vc, animated: animated, completion: completion)
        return proxy.promise.then(on: zalgo) { info -> UIImage in
            if let img = info[UIImagePickerControllerEditedImage] as? UIImage {
                return img
            }
            if let img = info[UIImagePickerControllerOriginalImage] as? UIImage {
                return img
            }
            throw Error.NoImageFound
        }.always {
            vc.presentingViewController?.dismissViewControllerAnimated(animated, completion: nil)
        }
    }

    public func promiseViewController(vc: UIImagePickerController, animated: Bool = true, completion: (() -> Void)? = nil) -> Promise<[String: AnyObject]> {
        let proxy = UIImagePickerControllerProxy()
        vc.delegate = proxy
        presentViewController(vc, animated: animated, completion: completion)
        return proxy.promise.always {
            vc.presentingViewController?.dismissViewControllerAnimated(animated, completion: nil)
        }
    }
}

@objc(Promisable) public protocol Promisable {
    /**
     Provide a promise for promiseViewController here.

     The resulting property must be annotated with @objc.

     Obviously return a Promise<T>. There is an issue with generics and Swift and
     protocols currently so we couldn't specify that.
    */
    var promise: AnyObject! { get }
}


// internal scope because used by ALAssetsLibrary extension
@objc class UIImagePickerControllerProxy: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let (promise, fulfill, reject) = Promise<[String : AnyObject]>.pendingPromise()
    var retainCycle: AnyObject?

    required override init() {
        super.init()
        retainCycle = self
    }

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        fulfill(info)
        retainCycle = nil
    }

    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        reject(UIImagePickerController.Error.Cancelled)
        retainCycle = nil
    }
}


extension UIImagePickerController {
    public enum Error: CancellableErrorType {
        case Cancelled

        public var cancelled: Bool {
            switch self {
                case .Cancelled: return true
            }
        }
    }
}
