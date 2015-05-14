import AssetsLibrary
import Foundation.NSData
import PromiseKit
import UIKit.UIViewController

/**
 To import this `UIViewController` extension:

    use_frameworks!
    pod "PromiseKit/AssetsLibrary"

 And then in your sources:

    import PromiseKit
*/
extension UIViewController {
    /**
      @return A promise that presents the provided UIImagePickerController and
      fulfills with the user selected media’s `NSData`.
     */
    public func promiseViewController(vc: UIImagePickerController, animated: Bool = false, completion: (() -> Void)? = nil) -> Promise<NSData> {
        let proxy = UIImagePickerControllerProxy()
        vc.delegate = proxy

        presentViewController(vc, animated: animated, completion: completion)

        return proxy.promise.then(on: zalgo) { info -> Promise<NSData> in
            let url = info[UIImagePickerControllerReferenceURL] as! NSURL
            
            return Promise { sealant in
                ALAssetsLibrary().assetForURL(url, resultBlock: { asset in
                    let N = Int(asset.defaultRepresentation().size())
                    let bytes = UnsafeMutablePointer<UInt8>.alloc(N)
                    var error: NSError?
                    asset.defaultRepresentation().getBytes(bytes, fromOffset: 0, length: N, error: &error)
                    
                    sealant.resolve(NSData(bytesNoCopy: bytes, length: N), error as NSError!)
                    
                }, failureBlock: sealant.resolve)
            }
        }.finally {
            self.dismissViewControllerAnimated(animated, completion: nil)
        }
    }
}
