import Foundation.NSProgress

private func _when<T>(_ promises: [Promise<T>]) -> Promise<Void> {
    let root = Promise<Void>.pending()
    var countdown = promises.count
    guard countdown > 0 else {
        root.fulfill()
        return root.promise
    }

#if !PMKDisableProgress
    let progress = Progress(totalUnitCount: Int64(promises.count))
    progress.isCancellable = false
    progress.isPausable = false
#else
    var progress: (completedUnitCount: Int, totalUnitCount: Int) = (0, 0)
#endif
    
    let barrier = DispatchQueue(label: "org.promisekit.barrier.when", attributes: .concurrent)

    for (index, promise) in promises.enumerated() {
        promise.state.pipe { resolution in
            __dispatch_barrier_sync(barrier) {
                switch resolution {
                case .rejected(let error, let token):
                    token.consumed = true   // all errors are consumed by the parent Error.When
                    if root.promise.isPending {
                        progress.completedUnitCount = progress.totalUnitCount
                        root.reject(Error.when(index, error))
                    }
                case .fulfilled:
                    guard root.promise.isPending else { return }
                    progress.completedUnitCount += 1
                    countdown -= 1
                    if countdown == 0 {
                        root.fulfill()
                    }
                }
            }
        }
    }

    return root.promise
}

/**
 Wait for all promises in a set to resolve.

 For example:

     when(promise1, promise2).then { results in
         //…
     }.error { error in
         switch error {
         case Error.When(let index, NSURLError.NoConnection):
             //…
         case Error.When(let index, CLError.NotAuthorized):
             //…
         }
     }

 - Note: If *any* of the provided promises reject, the returned promise is immediately rejected with `Error.when` which wraps the failing promises's error.
 - Warning: In the event of rejection the other promises will continue to resolve and, as per any other promise, will either fulfill or reject. This is the right pattern for `getter` style asynchronous tasks, but often for `setter` tasks (eg. storing data on a server), you most likely will need to wait on all tasks and then act based on which have succeeded and which have failed, in such situations use `when(resolved:)`.
 - Parameter promises: The promises upon which to wait before the returned promise resolves.
 - Returns: A new promise that resolves when all the provided promises fulfill or one of the provided promises rejects.
 - SeeAlso: `when(resolved:)`
 - SeeAlso: `PromiseKit.Error.when`
*/
public func when<T>(fulfilled promises: [Promise<T>]) -> Promise<[T]> {
    return _when(promises).then(on: zalgo) { promises.map{ $0.value! } }
}

/// - See: `when`
public func when<T>(fulfilled promises: Promise<T>...) -> Promise<[T]> {
    return when(fulfilled: promises)
}

/// - See: `when`
public func when(fulfilled promises: Promise<Void>...) -> Promise<Void> {
    return _when(promises)
}

/// - See: `when`
public func when(fulfilled promises: [Promise<Void>]) -> Promise<Void> {
    return _when(promises)
}

/// - See: `when`
public func when<U, V>(fulfilled pu: Promise<U>, _ pv: Promise<V>) -> Promise<(U, V)> {
    return _when([pu.asVoid(), pv.asVoid()]).then(on: zalgo) { (pu.value!, pv.value!) }
}

/// - See: `when`
public func when<U, V, X>(fulfilled pu: Promise<U>, _ pv: Promise<V>, _ px: Promise<X>) -> Promise<(U, V, X)> {
    return _when([pu.asVoid(), pv.asVoid(), px.asVoid()]).then(on: zalgo) { (pu.value!, pv.value!, px.value!) }
}

@available(*, unavailable, renamed: "when(fulfilled:)")
public func when<T>(_ promises: AnyObject...) -> Promise<T> { abort() }
