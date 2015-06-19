import Dispatch
import Foundation.NSError

public let PMKJoinPromises = "PMKPromises"
public let PMKJoinError = 100


/**
 Waits on all provided promises.

 `when` rejects as soon as one of the provided promises rejects. `join` waits on all provided promises, then rejects if any of those promises rejected, otherwise it fulfills with values from the provided promises.

     join(promise1, promise2, promise3).then { results in
         //…
     }.catch { error in
         for promise in error.userInfo[PMKJoinPromises] {
             if promise.rejected {
                 //…
             } else {
                 //…
             }
         }
     }

 - Returns: A new promise that resolves once all the provided promises resolve.
*/
public func join<T>(promises: Promise<T>...) -> Promise<[T]> {
    var countdown = promises.count
    let barrier = dispatch_queue_create("org.promisekit.barrier.join", DISPATCH_QUEUE_CONCURRENT)
    var rejected = false

    return Promise { fulfill, reject in
        for promise in promises {
            promise.pipe { resolution in
                dispatch_barrier_sync(barrier) {
                    if case .Rejected = resolution { rejected = true }

                    if --countdown == 0 {
                        if rejected {
                            var info = [NSObject:AnyObject]()
                            info[PMKJoinPromises] = promises
                            reject(NSError(domain: PMKErrorDomain, code: PMKJoinError, userInfo: info))
                        } else {
                            fulfill(promises.map{ $0.value! })
                        }
                    }
                }
            }
        }
    }
    
}
