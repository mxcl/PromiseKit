#if canImport(Photos)

import Photos.PHPhotoLibrary
#if !PMKCocoaPods
import PromiseKit
#endif

/**
     import PMKPhotos
*/
@available(macOS 10.13, *)
extension PHPhotoLibrary {
    /**
     - Returns: A promise that fulfills with the user’s authorization
     - Note: This promise cannot reject.
     */
    public class func requestAuthorization() -> Guarantee<PHAuthorizationStatus> {
        return Guarantee(resolver: PHPhotoLibrary.requestAuthorization)
    }
}

#endif
