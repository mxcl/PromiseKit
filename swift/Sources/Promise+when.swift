extension Promise {
    class func when<U,V>(promise1: Promise<U>, promise2: Promise<V>) -> Promise<(U,V)> {
        let (promise, fulfiller, rejecter) = Promise<(U,V)>.defer()
        var first:Any?
        promise1.then{ u->() in
            if first {
                let fulfillment = (u, first as V)
                fulfiller(fulfillment)
            } else {
                first = u
            }
        }
        promise2.then{ v->() in
            if first {
                let fulfillment = (first as U, v)
                fulfiller(fulfillment)
            } else {
                first = v
            }
        }
        promise1.catch(rejecter)
        promise2.catch(rejecter)
        return promise
    }

//
//    class func when(promises:Promise<AnyObject>...) -> Promise<AnyObject[]> {
//
//        if promises.count == 0 {
//            return Promise<AnyObject[]>(value:AnyObject[]())
//        }
//
//        let mapped = promises.map{ (p:AnyObject) -> Promise<AnyObject> in
//            if p is Promise {
//                return p as Promise<AnyObject>
//            } else {
//                return Promise<AnyObject>(value:p)
//            }
//        }
//
//        let (promise, fulfiller, rejecter) = Promise<AnyObject[]>.defer()
//        let results = Array<AnyObject>(count: promises.count, repeatedValue: NSNull())
//        var x = 0
//        for (index, promise) in enumerate(promises) {
//            promise.then{ value -> Void in
//                results[index] = value
//                if ++x == promises.count {
//                    fulfiller(results)
//                }
//            }
//            promise.catch(rejecter)  //TODO when we have cancelation, cancel all!
//        }
//
//        return promise
//    }
}
