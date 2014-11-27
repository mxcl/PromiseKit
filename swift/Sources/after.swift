import Foundation

public func after(delay: NSTimeInterval, q: dispatch_queue_t = dispatch_get_main_queue()) -> Promise<NSTimeInterval> {
    return Promise { fulfill, _ in
        let delta = delay * NSTimeInterval(NSEC_PER_SEC)
        let when = dispatch_time(DISPATCH_TIME_NOW, Int64(delta))
        dispatch_after(when, q) {
            fulfill(delay)
        }
    }
}
