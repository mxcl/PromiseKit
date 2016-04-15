import Bolts
import PromiseKit

extension Promise {
    public func then(on q: dispatch_queue_t = PMKDefaultDispatchQueue(), body: (T) -> BFTask) -> Promise<AnyObject?> {
        return then(on: q) { tee -> Promise<AnyObject?> in
            let task = body(tee)
            return Promise<AnyObject?> { fulfill, reject in
                task.continueWithBlock { task in
                    if task.completed {
                        fulfill(task.result)
                    } else {
                        reject(task.error!)
                    }
                    return nil
                }
            }
        }
    }
}

extension BFTask {
    public func then<T>(on q: dispatch_queue_t = PMKDefaultDispatchQueue(), body: (AnyObject?) -> T) -> Promise<T> {
        return Promise { fulfill, reject in
            continueWithBlock { task in
                if task.completed {
                    dispatch_async(q) {  //FIXME zalgo
                        fulfill(body(task.result))
                    }
                } else {
                    reject(task.error!)
                }
                return nil
            }
        }
    }
}
