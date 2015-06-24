import Dispatch
import Foundation.NSError

public func dispatch_promise<T>(on queue: dispatch_queue_t = dispatch_get_global_queue(0, 0), body: () throws -> T) -> Promise<T> {
    return Promise { fulfill, reject in
        contain_zalgo(queue) {
            do {
                fulfill(try body())
            } catch let error {
                reject(error as NSError)
            }
        }
    }
}
