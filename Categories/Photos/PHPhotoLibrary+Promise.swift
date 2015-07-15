import Photos.PHPhotoLibrary
#if !COCOAPODS
import PromiseKit
#endif

/**
 To import the `PHPhotoLibrary` category:

    use_frameworks!
    pod "PromiseKit/Photos"

 And then in your sources:

    import PromiseKit
*/
extension PHPhotoLibrary {
    public class func requestAuthorization() -> Promise<PHAuthorizationStatus> {
        return Promise { fulfill, _ in PHPhotoLibrary.requestAuthorization(fulfill) }
    }
}
