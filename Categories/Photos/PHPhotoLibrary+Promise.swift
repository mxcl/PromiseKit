import PromiseKit
import Photos.PHPhotoLibrary

/**
 To import the `PHPhotoLibrary` category:

    use_frameworks!
    pod "PromiseKit/Photos"

 And then in your sources:

    import PromiseKit
*/
extension PHPhotoLibrary {
    public class func requestAuthorization() -> Promise<PHAuthorizationStatus> {
        return Promise { requestAuthorization($0.resolve) }
    }
}
