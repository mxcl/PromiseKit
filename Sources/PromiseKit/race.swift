import struct Foundation.TimeInterval
import Dispatch

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
 Resolves with the first resolving cancellable promise from a set of cancellable promises. Calling
 `cancel` on the race promise cancels all pending promises. All promises will be cancelled if any
 promise rejects.

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
 Resolves with the first resolving promise from a set of promises. Calling `cancel` on the race
 promise cancels all pending promises. All promises will be cancelled if any promise rejects.

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

    let cancelThenables: (Result<V.U.T, Error>) -> Void = { result in
        if case .failure = result {
            for t in thenables {
                if !t.cancelAttempted {
                    t.cancel()
                }
            }
        }
    }

    let promise = CancellablePromise(race(asThenables(thenables)))
    for t in thenables {
        t.thenable.pipe(to: cancelThenables)
        promise.appendCancelContext(from: t)
    }
    return promise
}

/**
 Waits for one promise to fulfill

     race(fulfilled: [promise1, promise2, promise3]).then { winner in
         //…
     }

 - Returns: The promise that was fulfilled first.
 - Warning: Skips all rejected promises.
 - Remark: If the provided array is empty, the returned promise is rejected with `PMKError.badInput`. If there are no fulfilled promises, the returned promise is rejected with `PMKError.noWinner`.
*/
public func race<U: Thenable>(fulfilled thenables: [U]) -> Promise<U.T> {
    var countdown = thenables.count
    guard countdown > 0 else {
        return Promise(error: PMKError.badInput)
    }

    let rp = Promise<U.T>(.pending)

    let barrier = DispatchQueue(label: "org.promisekit.barrier.race", attributes: .concurrent)

    for promise in thenables {
        promise.pipe { result in
            barrier.sync(flags: .barrier) {
                switch result {
                case .failure:
                    guard rp.isPending else { return }
                    countdown -= 1
                    if countdown == 0 {
                        rp.box.seal(.failure(PMKError.noWinner))
                    }
                case .success(let value):
                    guard rp.isPending else { return }
                    countdown = 0
                    rp.box.seal(.success(value))
                }
            }
        }
    }

    return rp
}

/**
 Returns a promise that can be used to set a timeout for `race`.

     let promise1, promise2: Promise<Void>
     race(promise1, promise2, timeout(seconds: 1.0)).done { winner in
         //…
     }.catch(policy: .allErrors) {
         // Rejects with `PMKError.timedOut` if the timeout is exceeded before either `promise1` or
         // `promise2` succeeds.
     }

 When used with cancellable promises, all promises will be cancelled if the timeout is
 exceeded or any promise rejects:

     let promise1, promise2: CancellablePromise<Void>
     race(promise1, promise2, cancellize(timeout(seconds: 1.0))).done { winner in
         //…
     }
 */
public func timeout(seconds: TimeInterval) -> Promise<Void> {
    return after(seconds: seconds).done { throw PMKError.timedOut }
}
