import AVFoundation
import Foundation
#if !COCOAPODS
import PromiseKit
#endif

/**
 To import the `AVAudioSession` category:

    use_frameworks!
    pod "PromiseKit/AVFoundation"

 And then in your sources:

    #if !COCOAPODS
import PromiseKit
#endif
*/
extension AVAudioSession {
    public func requestRecordPermission() -> Promise<Bool> {
        return Promise { fulfill, _ in
            requestRecordPermission(fulfill)
        }
    }
}
