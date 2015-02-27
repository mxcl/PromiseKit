/**
 This general `when` is not the most useful since everything becomes
 `AnyObject`. Swift generics are not ready for arbituary numbers of
 varying generic types, so this is the best you get if you have more
 than two things you need to `when` currently.
*/
private enum PromiseResult<T> {
    case Busy
    case Fulfilled(T)
}

public func when<T>(promises: [Promise<T>]) -> Promise<[T]> {
    if promises.isEmpty {
        return Promise<[T]>(value:[])
    }
    let (promise, fulfiller, rejecter) = Promise<[T]>.defer()
    var results = [PromiseResult<T>](count: promises.count, repeatedValue: PromiseResult.Busy)
    var x = 0
    for (index, promise) in enumerate(promises) {
        promise.then{ (value) -> Void in
            results[index] = .Fulfilled(value)
            if ++x == promises.count {
                var values: [T] = []
                for result in results {
                    switch result {
                    case .Busy:
                        // Does not happen in practise but makes the compiler happy
                        break
                    case .Fulfilled(let value):
                        values.append(value)
                    }
                }
                fulfiller(values)
            }
        }
        promise.catch(body: rejecter)
    }
    return promise
}

public func when<T>(promises: Promise<T>...) -> Promise<[T]> {
    return when(promises)
}

public func when<U,V>(promise1: Promise<U>, promise2: Promise<V>) -> Promise<(U,V)> {
    let (promise, fulfiller, rejecter) = Promise<(U,V)>.defer()
    var first:Any?
    promise1.then{ u->() in
        if let seal = first {
            let fulfillment = (u, seal as! V)
            fulfiller(fulfillment)
        } else {
            first = u
        }
    }
    promise2.then{ v->() in
        if let seal = first {
            let fulfillment = (seal as! U, v)
            fulfiller(fulfillment)
        } else {
            first = v
        }
    }
    promise1.catch(body: rejecter)
    promise2.catch(body: rejecter)
    return promise
}

// For Void Promises we don't need type accumulations, so we can use recursion easily
private func when(promise1: Promise<Void>, # promise2: Promise<Void>) -> Promise<Void> {
    let (promise, fulfiller, rejecter) = Promise<Void>.defer()
    var first: Any?

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
    let _:Void = promise1.catch(body: rejecter)
    let _:Void = promise2.catch(body: rejecter)
    return promise
}

/**
 If your promises are all Void promises, then this will work for you.
 TODO use the ... form once Swift isn't fucking brain dead about figuring out which when to pick
 */
public func when(promises: [Promise<Void>]) -> Promise<Void> {
    switch promises.count {
    case 0:
        return Promise<Void>(value:())
    case 1:
        return promises[0]
    case 2:
        return when(promises[0], promise2: promises[1])
    default:
        let head = Array(promises[0..<promises.count - 1])
        let tail = promises[promises.count - 1]
        return when(when(head), promise2: tail)
    }
}
