#if !COCOAPODS
import PromiseKit
#endif
import Photos.PHPhotoLibrary

/**
 To import the `PHPhotoLibrary` category:

    use_frameworks!
    pod "PromiseKit/Photos"

 And then in your sources:

    #if !COCOAPODS
import PromiseKit
#endif
*/
extension PHPhotoLibrary {
    public class func requestAuthorization() -> Promise<PHAuthorizationStatus> {
        return Promise { requestAuthorization($0.resolve) }
    }
}
