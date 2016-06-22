import Dispatch
import Foundation.NSDate

/**
 ```
 after(1).then {
     //…
 }
 ```

 - Returns: A new promise that resolves after the specified duration.
 - Parameter duration: The duration in seconds to wait before this promise is resolve.
*/
public func after(_ delay: TimeInterval) -> Promise<Void> {
    return Promise { fulfill, _ in
        let when = DispatchTime.now() + delay
        DispatchQueue.global().after(when: when, execute: fulfill)
    }
}
