import struct Foundation.TimeInterval
import Dispatch

/**
 ```
 after(interval: 1.1).then {
     //…
 }
 ```

 - Returns: A new promise that resolves after the specified duration.
 - Parameter interval: The duration in seconds to wait before this promise is resolve.
*/
public func after(interval: TimeInterval) -> Promise<Void> {
    return Promise { fulfill, _ in
        let when = DispatchTime.now() + interval
        DispatchQueue.global().after(when: when, execute: fulfill)
    }
}
