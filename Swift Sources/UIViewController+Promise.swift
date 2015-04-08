import UIKit
import MessageUI.MFMailComposeViewController
import Social.SLComposeViewController
import AssetsLibrary.ALAssetsLibrary


class MFMailComposeViewControllerProxy: NSObject, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate {

    override init() {
        super.init()
        PMKRetain(self)
    }

    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
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
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        picker.fulfill(info as NSDictionary?)
    }

    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.fulfill(nil as NSDictionary?)
    }
}

class Resolver {
    let fulfill: (Any) -> Void
    let reject: (NSError) -> Void
    init(fulfill: (Any) -> Void, reject: (NSError) -> Void) {
        self.fulfill = fulfill
        self.reject = reject
    }
}

private var key = "PMKSomeString"

extension UIViewController {
    public func fulfill(value: Any) {
        let resolver = objc_getAssociatedObject(self, &key) as Resolver
        resolver.fulfill(value)
    }

    public func reject(error:NSError) {
        let resolver = objc_getAssociatedObject(self, &key) as Resolver
        resolver.reject(error)
    }

    public func promiseViewController<T: Any>(vc: UIViewController, animated: Bool = true, completion:(Void)->() = {}) -> Promise<T> {
        presentViewController(vc, animated:animated, completion:completion)

        let (promise, f, r) = Promise<T>.defer()
        let fwrap = { (any: Any) in
            f(any as T)
        }

        objc_setAssociatedObject(vc, &key, Resolver(fulfill: fwrap, reject: r), UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))

        return promise.finally { _ in
            self.dismissViewControllerAnimated(animated, completion:nil)
        }
    }

    public func promiseViewController<T>(nc: UINavigationController, animated: Bool = false, completion:(Void)->() = {}) -> Promise<T> {
        let vc = nc.viewControllers[0] as! UIViewController
        return promiseViewController(vc, animated: animated, completion: completion)
    }

    public func promiseViewController(vc: MFMailComposeViewController, animated: Bool = false, completion:(Void)->() = {}) -> Promise<Int> {
        vc.mailComposeDelegate = MFMailComposeViewControllerProxy()
        return promiseViewController(vc as UIViewController, animated: animated, completion: completion)
    }

    public func promiseViewController(vc: UIImagePickerController, animated: Bool = false, completion:()->() = {}) -> Promise<UIImage?> {
        let delegate = UIImagePickerControllerProxy()
        vc.delegate = delegate
        PMKRetain(delegate)
        return promiseViewController(vc as UIViewController, animated: animated, completion: completion).then{
            (info: NSDictionary?) -> UIImage? in
            return info?.objectForKey(UIImagePickerControllerOriginalImage) as! UIImage?
        }.finally {
            PMKRelease(delegate)
        }
    }

    public func promiseViewController(vc: UIImagePickerController, animated: Bool = false, completion:(Void)->() = {}) -> Promise<NSData?> {
        let delegate = UIImagePickerControllerProxy()
        vc.delegate = delegate
        PMKRetain(delegate)
        return promiseViewController(vc as UIViewController, animated: animated, completion: completion).then{
            (info: NSDictionary?) -> Promise<NSData?> in

            if info == nil { return Promise<NSData?>(value: nil) }

            let url = info![UIImagePickerControllerReferenceURL] as! NSURL

            return Promise { (fulfill, reject) in
                ALAssetsLibrary().assetForURL(url, resultBlock:{ asset in
                    let N = Int(asset.defaultRepresentation().size())
                    let bytes = UnsafeMutablePointer<UInt8>.alloc(N)
                    var error: NSError?
                    asset.defaultRepresentation().getBytes(bytes, fromOffset:0, length:N, error:&error)
                    if error != nil {
                        reject(error!)
                    } else {
                        let data = NSData(bytesNoCopy: bytes, length: N)
                        fulfill(data)
                    }
                }, failureBlock:{
                    reject($0)
                })
            }
        }.finally {
            PMKRelease(delegate)
        }
    }

    public func promiseViewController(vc: SLComposeViewController, animated: Bool = false, completion:(Void)->() = {}) -> Promise<SLComposeViewControllerResult> {
        return Promise { (fulfill, reject) in
            vc.completionHandler = { (result: SLComposeViewControllerResult) in
                fulfill(result)
                self.dismissViewControllerAnimated(animated, completion: nil)
            }
            self.presentViewController(vc, animated: animated, completion: completion)
        }
    }
}
