import UIKit
import MessageUI

class MFMailComposeViewControllerProxy: NSObject, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate {

    override init() {
        super.init()
        PMKRetain(self)
    }

    func mailComposeController(controller:MFMailComposeViewController!, didFinishWithResult result:Int, error:NSError!) {
        if error != nil {
            controller.reject(error)
        } else {
            controller.fulfill(result)
        }
        PMKRelease(self)
    }
}

class UIImagePickerControllerProxy: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingMediaWithInfo info: NSDictionary!) {
        let o = info.objectForKey(UIImagePickerControllerOriginalImage) as UIImage!
        picker.fulfill(o as UIImage?)
    }

    func imagePickerControllerDidCancel(picker: UIImagePickerController!) {
        picker.fulfill(nil as UIImage?)
    }
}

class Resolver<T> {
    let fulfiller: (T) -> Void
    let rejecter: (NSError) -> Void
    init(_ deferred: (Promise<T>, (T)->Void, (NSError)->Void)) {
        (_, self.fulfiller, self.rejecter) = deferred
    }
}

var key = "PMKSomeString"

extension UIViewController {
    func fulfill<T>(value:T) {
        let resolver = objc_getAssociatedObject(self, &key) as Resolver<T>
        resolver.fulfiller(value)
    }

    func reject(error:NSError) {
        let resolver = objc_getAssociatedObject(self, &key) as Resolver<Any>;
        resolver.rejecter(error)
    }

    public func promiseViewController<T>(vc: UIViewController, animated: Bool = true, completion:(Void)->() = {}) -> Promise<T> {
        presentViewController(vc, animated:animated, completion:completion)

        let deferred = Promise<T>.defer()

        objc_setAssociatedObject(vc, &key, Resolver<T>(deferred), UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))

        return deferred.promise.finally { () -> () in
            self.dismissViewControllerAnimated(animated, completion:nil)
        }
    }

    public func promiseViewController<T>(nc: UINavigationController, animated: Bool = false, completion:(Void)->() = {}) -> Promise<T> {
        let vc = nc.viewControllers[0] as UIViewController
        return promiseViewController(vc, animated: animated, completion: completion)
    }

    public func promiseViewController(vc: MFMailComposeViewController, animated: Bool = false, completion:(Void)->() = {}) -> Promise<Int> {
        vc.delegate = MFMailComposeViewControllerProxy()
        return promiseViewController(vc as UIViewController, animated: animated, completion: completion)
    }

    public func promiseViewController(vc: UIImagePickerController, animated: Bool = false, completion:(Void)->() = {}) -> Promise<UIImage?> {
        let delegate = UIImagePickerControllerProxy()
        vc.delegate = delegate
        PMKRetain(delegate)
        return promiseViewController(vc as UIViewController, animated: animated, completion: completion).finally {
            PMKRelease(vc.delegate)
        }
    }
}
