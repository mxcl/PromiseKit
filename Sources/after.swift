import struct Foundation.TimeInterval
import Dispatch

/**
 - Returns: A new promise that fulfills after the specified duration.
*/
public func after(interval: TimeInterval) -> Promise<Void> {
    return Promise { fulfill, _ in
        let when = DispatchTime.now() + interval
    #if swift(>=4.0)
        DispatchQueue.global().asyncAfter(deadline: when) { fulfill(()) }
    #else
        DispatchQueue.global().asyncAfter(deadline: when, execute: fulfill)
    #endif
    }
}
