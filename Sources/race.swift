@inline(__always)
private func _race<U: Thenable>(_ thenables: [U]) -> Promise<U.T> {
    let rp = Promise<U.T>(.pending)
    for thenable in thenables {
        thenable.pipe(to: rp.box.seal)
    }
    return rp
}

/**
 Waits for one promise to resolve

     race(promise1, promise2, promise3).then { winner in
         //…
     }

 - Returns: The promise that resolves first
 - Warning: If the first resolution is a rejection, the returned promise is rejected
*/
public func race<U: Thenable>(_ thenables: U...) -> Promise<U.T> {
    return _race(thenables)
}

/**
 Waits for one promise to resolve

     race(promise1, promise2, promise3).then { winner in
         //…
     }

 - Returns: The promise that resolves first
 - Warning: If the first resolution is a rejection, the returned promise is rejected
 - Remark: If the provided array is empty the returned promise is rejected with PMKError.badInput
*/
public func race<U: Thenable>(_ thenables: [U]) -> Promise<U.T> {
    guard !thenables.isEmpty else {
        return Promise(error: PMKError.badInput)
    }
    return _race(thenables)
}

/**
 Waits for one guarantee to resolve

     race(promise1, promise2, promise3).then { winner in
         //…
     }

 - Returns: The guarantee that resolves first
*/
public func race<T>(_ guarantees: Guarantee<T>...) -> Guarantee<T> {
    let rg = Guarantee<T>(.pending)
    for guarantee in guarantees {
        guarantee.pipe(to: rg.box.seal)
    }
    return rg
}

//////////////////////////////////////////////////////////// Cancellation

/**
 Resolves with the first resolving cancellable promise from a set of cancellable promises. Calling `cancel` on the
 race promise cancels all pending promises.

     let racePromise = race(promise1, promise2, promise3).then { winner in
         //…
     }
 
     //…
 
     racePromise.cancel()

 - Returns: A new promise that resolves when the first promise in the provided promises resolves.
 - Warning: If any of the provided promises reject, the returned promise is rejected.
 - Warning: aborts if the array is empty.
*/
public func race<V: CancellableThenable>(_ thenables: V...) -> CancellablePromise<V.U.T> {
    return race(thenables)
}

/**
 Resolves with the first resolving promise from a set of promises. Calling `cancel` on the
 race promise cancels all pending promises.

     let racePromise = race(promise1, promise2, promise3).then { winner in
         //…
     }
 
     //…
 
     racePromise.cancel()

 - Returns: A new promise that resolves when the first promise in the provided promises resolves.
 - Warning: If any of the provided promises reject, the returned promise is rejected.
 - Remark: Returns promise rejected with PMKError.badInput if empty array provided
*/
public func race<V: CancellableThenable>(_ thenables: [V]) -> CancellablePromise<V.U.T> {
    guard !thenables.isEmpty else {
        return CancellablePromise(error: PMKError.badInput)
    }
    
    let promise = CancellablePromise(race(asThenables(thenables)))
    for t in thenables {
        promise.appendCancelContext(from: t)
    }
    return promise
}
