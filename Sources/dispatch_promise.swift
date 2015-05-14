import Dispatch
import Foundation.NSError

public func dispatch_promise<T>(on queue: dispatch_queue_t = dispatch_get_global_queue(0, 0), body: () -> T) -> Promise<T> {
    return Promise { sealant in
        contain_zalgo(queue) {
            sealant.resolve(body())
        }
    }
}

// TODO Swift 1.2 thinks that usage of the following two is ambiguous
//public func dispatch_promise<T>(on queue: dispatch_queue_t = dispatch_get_global_queue(0, 0), body: () -> Promise<T>) -> Promise<T> {
//    return Promise { sealant in
//        contain_zalgo(queue) {
//            body().pipe(sealant.handler)
//        }
//    }
//}

public func dispatch_promise<T>(on: dispatch_queue_t = dispatch_get_global_queue(0, 0), body: () -> (T!, NSError!)) -> Promise<T> {
    return Promise{ (sealant: Sealant) -> Void in
        contain_zalgo(on) {
            let (a, b) = body()
            sealant.resolve(a, b)
        }
    }
}
