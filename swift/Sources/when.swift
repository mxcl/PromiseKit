public func when<U,V>(promise1: Promise<U>, promise2: Promise<V>) -> Promise<(U,V)> {
    let (promise, fulfiller, rejecter) = Promise<(U,V)>.defer()
    var first:Any?
    promise1.then{ u->() in
        if let seal = first {
            let fulfillment = (u, seal as V)
            fulfiller(fulfillment)
        } else {
            first = u
        }
    }
    promise2.then{ v->() in
        if let seal = first {
            let fulfillment = (seal as U, v)
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
//    func when(promises:Promise<AnyObject>...) -> Promise<AnyObject[]> {
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


// For Void Promises we don't need type accumulations, so we can use recursion easily
public func when(promise1: Promise<Void>, promise2: Promise<Void>) -> Promise<Void> {
    let (promise, fulfiller, rejecter) = Promise<Void>.defer()
    var first:Any?

    promise1.then { ()->() in
        if let other = first {
            fulfiller()
        } else {
            first = promise1
        }
    }
    
    promise2.then { ()->() in
        if let other = first {
            fulfiller()
        } else {
            first = promise2
        }
    }
    let _:Void = promise2.catch(rejecter)
    let _:Void = promise2.catch(rejecter)
    return promise
}

// recursively apply the 2 parameter form
public func when(promises: Array<Promise<Void>>) -> Promise<Void> {
    switch promises.count {
    case 0:
        return Promise<Void>(value:())
    case 1:
        return promises[0]
    case 2:
        return when(promises[0], promises[1])
    default:
        let head = Array(promises[0..<promises.count - 1])
        let tail = promises[promises.count - 1]
        return when(when(head), tail)
    }
}
