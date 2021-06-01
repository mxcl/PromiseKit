import Foundation
import Dispatch

private func _when<U: Thenable>(_ thenables: [U]) -> Promise<Void> {
    var countdown = thenables.count
    guard countdown > 0 else {
        return .value(Void())
    }

    let rp = Promise<Void>(.pending)

#if PMKDisableProgress || os(Linux) || os(Android)
    var progress: (completedUnitCount: Int, totalUnitCount: Int) = (0, 0)
#else
    let progress = Progress(totalUnitCount: Int64(thenables.count))
    progress.isCancellable = false
    progress.isPausable = false
#endif

    let barrier = DispatchQueue(label: "org.promisekit.barrier.when", attributes: .concurrent)

    for promise in thenables {
        promise.pipe { result in
            barrier.sync(flags: .barrier) {
                switch result {
                case .failure(let error):
                    if rp.isPending {
                        progress.completedUnitCount = progress.totalUnitCount
                        rp.box.seal(.failure(error))
                    }
                case .success:
                    guard rp.isPending else { return }
                    progress.completedUnitCount += 1
                    countdown -= 1
                    if countdown == 0 {
                        rp.box.seal(.success(()))
                    }
                }
            }
        }
    }

    return rp
}

/**
 Wait for all promises in a set to fulfill.

 For example:

     when(fulfilled: promise1, promise2).then { results in
         //…
     }.catch { error in
         switch error {
         case URLError.notConnectedToInternet:
             //…
         case CLError.denied:
             //…
         }
     }

 - Note: If *any* of the provided promises reject, the returned promise is immediately rejected with that error.
 - Warning: In the event of rejection the other promises will continue to resolve and, as per any other promise, will either fulfill or reject. This is the right pattern for `getter` style asynchronous tasks, but often for `setter` tasks (eg. storing data on a server), you most likely will need to wait on all tasks and then act based on which have succeeded and which have failed, in such situations use `when(resolved:)`.
 - Parameter promises: The promises upon which to wait before the returned promise resolves.
 - Returns: A new promise that resolves when all the provided promises fulfill or one of the provided promises rejects.
 - Note: `when` provides `NSProgress`.
 - SeeAlso: `when(resolved:)`
*/
public func when<U: Thenable>(fulfilled thenables: [U]) -> Promise<[U.T]> {
    return _when(thenables).map(on: nil) { thenables.map{ $0.value! } }
}

/// Wait for all promises in a set to fulfill.
public func when<U: Thenable>(fulfilled promises: U...) -> Promise<Void> where U.T == Void {
    return _when(promises)
}

/// Wait for all promises in a set to fulfill.
public func when<U: Thenable>(fulfilled promises: [U]) -> Promise<Void> where U.T == Void {
    return _when(promises)
}

/// Wait for all promises in a set to fulfill.
public func when<U: Thenable, V: Thenable>(fulfilled pu: U, _ pv: V) -> Promise<(U.T, V.T)> {
    return _when([pu.asVoid(), pv.asVoid()]).map(on: nil) { (pu.value!, pv.value!) }
}

/// Wait for all promises in a set to fulfill.
public func when<U: Thenable, V: Thenable, W: Thenable>(fulfilled pu: U, _ pv: V, _ pw: W) -> Promise<(U.T, V.T, W.T)> {
    return _when([pu.asVoid(), pv.asVoid(), pw.asVoid()]).map(on: nil) { (pu.value!, pv.value!, pw.value!) }
}

/// Wait for all promises in a set to fulfill.
public func when<U: Thenable, V: Thenable, W: Thenable, X: Thenable>(fulfilled pu: U, _ pv: V, _ pw: W, _ px: X) -> Promise<(U.T, V.T, W.T, X.T)> {
    return _when([pu.asVoid(), pv.asVoid(), pw.asVoid(), px.asVoid()]).map(on: nil) { (pu.value!, pv.value!, pw.value!, px.value!) }
}

/// Wait for all promises in a set to fulfill.
public func when<U: Thenable, V: Thenable, W: Thenable, X: Thenable, Y: Thenable>(fulfilled pu: U, _ pv: V, _ pw: W, _ px: X, _ py: Y) -> Promise<(U.T, V.T, W.T, X.T, Y.T)> {
    return _when([pu.asVoid(), pv.asVoid(), pw.asVoid(), px.asVoid(), py.asVoid()]).map(on: nil) { (pu.value!, pv.value!, pw.value!, px.value!, py.value!) }
}

/**
 Generate promises at a limited rate and wait for all to fulfill.

 For example:
 
     func downloadFile(url: URL) -> Promise<Data> {
         // …
     }
 
     let urls: [URL] = /*…*/
     let urlGenerator = urls.makeIterator()

     let generator = AnyIterator<Promise<Data>> {
         guard url = urlGenerator.next() else {
             return nil
         }
         return downloadFile(url)
     }

     when(generator, concurrently: 3).done { datas in
         // …
     }
 
 No more than three downloads will occur simultaneously.

 - Note: The generator is called *serially* on a *background* queue.
 - Warning: Refer to the warnings on `when(fulfilled:)`
 - Parameter promiseGenerator: Generator of promises.
 - Returns: A new promise that resolves when all the provided promises fulfill or one of the provided promises rejects.
 - SeeAlso: `when(resolved:)`
 */

public func when<It: IteratorProtocol>(fulfilled promiseIterator: It, concurrently: Int) -> Promise<[It.Element.T]> where It.Element: Thenable {

    guard concurrently > 0 else {
        return Promise(error: PMKError.badInput)
    }

    var generator = promiseIterator
    let root = Promise<[It.Element.T]>.pending()
    var pendingPromises = 0
    var promises: [It.Element] = []

    let barrier = DispatchQueue(label: "org.promisekit.barrier.when", attributes: [.concurrent])

    func dequeue() {
        guard root.promise.isPending else { return }  // don’t continue dequeueing if root has been rejected

        var shouldDequeue = false
        barrier.sync {
            shouldDequeue = pendingPromises < concurrently
        }
        guard shouldDequeue else { return }

        var promise: It.Element!

        barrier.sync(flags: .barrier) {
            guard let next = generator.next() else { return }
            promise = next
            pendingPromises += 1
            promises.append(next)
        }

        func testDone() {
            barrier.sync {
                if pendingPromises == 0 {
                    root.resolver.fulfill(promises.compactMap{ $0.value })
                }
            }
        }

        guard promise != nil else {
            return testDone()
        }

        promise.pipe { resolution in
            barrier.sync(flags: .barrier) {
                pendingPromises -= 1
            }

            switch resolution {
            case .success:
                dequeue()
                testDone()
            case .failure(let error):
                root.resolver.reject(error)
            }
        }

        dequeue()
    }
        
    dequeue()

    return root.promise
}

/**
 Waits on all provided promises.

 `when(fulfilled:)` rejects as soon as one of the provided promises rejects. `when(resolved:)` waits on all provided promises whatever their result, and then provides an array of `Result<T>` so you can individually inspect the results. As a consequence this function returns a `Guarantee`, ie. errors are lifted from the individual promises into the results array of the returned `Guarantee`.

     when(resolved: promise1, promise2, promise3).then { results in
         for result in results where case .success(let value) {
            //…
         }
     }.catch { error in
         // invalid! Never rejects
     }

 - Returns: A new promise that resolves once all the provided promises resolve. The array is ordered the same as the input, ie. the result order is *not* resolution order.
 - Note: we do not provide tuple variants for `when(resolved:)` but will accept a pull-request
 - Remark: Doesn't take Thenable due to protocol `associatedtype` paradox
*/
public func when<T>(resolved promises: Promise<T>...) -> Guarantee<[Result<T, Error>]> {
    return when(resolved: promises)
}

/// - See: `when(resolved: Promise<T>...)`
public func when<T>(resolved promises: [Promise<T>]) -> Guarantee<[Result<T, Error>]> {
    guard !promises.isEmpty else {
        return .value([])
    }

    var countdown = promises.count
    let barrier = DispatchQueue(label: "org.promisekit.barrier.join", attributes: .concurrent)

    let rg = Guarantee<[Result<T, Error>]>(.pending)
    for promise in promises {
        promise.pipe { result in
            barrier.sync(flags: .barrier) {
                countdown -= 1
            }
            barrier.sync {
                if countdown == 0 {
                    rg.box.seal(promises.map{ $0.result! })
                }
            }
        }
    }
    return rg
}

/**
Generate promises at a limited rate and wait for all to resolve.

For example:

    func downloadFile(url: URL) -> Promise<Data> {
        // ...
    }

    let urls: [URL] = /*…*/
    let urlGenerator = urls.makeIterator()

    let generator = AnyIterator<Promise<Data>> {
        guard url = urlGenerator.next() else {
            return nil
        }
        return downloadFile(url)
    }

    when(resolved: generator, concurrently: 3).done { results in
        // ...
    }

No more than three downloads will occur simultaneously. Downloads will continue if one of them fails

- Note: The generator is called *serially* on a *background* queue.
- Warning: Refer to the warnings on `when(resolved:)`
- Parameter promiseGenerator: Generator of promises.
- Returns: A new promise that resolves once all the provided promises resolve. The array is ordered the same as the input, ie. the result order is *not* resolution order.
- SeeAlso: `when(resolved:)`
*/
#if swift(>=5.3)
public func when<It: IteratorProtocol>(resolved promiseIterator: It, concurrently: Int)
    -> Guarantee<[Result<It.Element.T, Error>]> where It.Element: Thenable {
    guard concurrently > 0 else {
        return Guarantee.value([Result.failure(PMKError.badInput)])
    }

    var generator = promiseIterator
    let root = Guarantee<[Result<It.Element.T, Error>]>.pending()
    var pendingPromises = 0
    var promises: [It.Element] = []

    let barrier = DispatchQueue(label: "org.promisekit.barrier.when", attributes: [.concurrent])

    func dequeue() {
        guard root.guarantee.isPending else {
            return
        }  // don’t continue dequeueing if root has been rejected

        var shouldDequeue = false
        barrier.sync {
            shouldDequeue = pendingPromises < concurrently
        }
        guard shouldDequeue else {
            return
        }

        var promise: It.Element!

        barrier.sync(flags: .barrier) {
            guard let next = generator.next() else {
                return
            }

            promise = next

            pendingPromises += 1
            promises.append(next)
        }

        func testDone() {
            barrier.sync {
                if pendingPromises == 0 {
                  #if !swift(>=3.3) || (swift(>=4) && !swift(>=4.1))
                    root.resolve(promises.flatMap { $0.result })
                  #else
                    root.resolve(promises.compactMap { $0.result })
                  #endif
                }
            }
        }

        guard promise != nil else {
            return testDone()
        }

        promise.pipe { _ in
            barrier.sync(flags: .barrier) {
                pendingPromises -= 1
            }

            dequeue()
            testDone()
        }

        dequeue()
    }

    dequeue()

    return root.guarantee
}
#endif

/// Waits on all provided Guarantees.
public func when(_ guarantees: Guarantee<Void>...) -> Guarantee<Void> {
    return when(guarantees: guarantees)
}

// Waits on all provided Guarantees.
public func when(guarantees: [Guarantee<Void>]) -> Guarantee<Void> {
    return when(fulfilled: guarantees).recover{ _ in }.asVoid()
}

//////////////////////////////////////////////////////////// Cancellation

/**
 Wait for all cancellable promises in a set to fulfill.

 For example:

     let p = when(fulfilled: promise1, promise2).then { results in
         //…
     }.catch { error in
         switch error {
         case URLError.notConnectedToInternet:
             //…
         case CLError.denied:
             //…
         }
     }
 
     //…

     p.cancel()

 - Note: If *any* of the provided promises reject, the returned promise is immediately rejected with that error.
 - Warning: In the event of rejection the other promises will continue to resolve and, as per any other promise, will either fulfill or reject. This is the right pattern for `getter` style asynchronous tasks, but often for `setter` tasks (eg. storing data on a server), you most likely will need to wait on all tasks and then act based on which have succeeded and which have failed, in such situations use `when(resolved:)`.
 - Parameter promises: The promises upon which to wait before the returned promise resolves.
 - Returns: A new promise that resolves when all the provided promises fulfill or one of the provided promises rejects.
 - Note: `when` provides `NSProgress`.
 - SeeAlso: `when(resolved:)`
*/
public func when<V: CancellableThenable>(fulfilled thenables: V...) -> CancellablePromise<[V.U.T]> {
    let rp = CancellablePromise(when(fulfilled: asThenables(thenables)))
    for t in thenables {
        rp.appendCancelContext(from: t)
    }
    return rp
}

public func when<V: CancellableThenable>(fulfilled thenables: [V]) -> CancellablePromise<[V.U.T]> {
    let rp = CancellablePromise(when(fulfilled: asThenables(thenables)))
    for t in thenables {
        rp.appendCancelContext(from: t)
    }
    return rp
}

/// Wait for all cancellable promises in a set to fulfill.
public func when<V: CancellableThenable>(fulfilled promises: V...) -> CancellablePromise<Void> where V.U.T == Void {
    let rp = CancellablePromise(when(fulfilled: asThenables(promises)))
    for p in promises {
        rp.appendCancelContext(from: p)
    }
    return rp
}

/// Wait for all cancellable promises in a set to fulfill.
public func when<V: CancellableThenable>(fulfilled promises: [V]) -> CancellablePromise<Void> where V.U.T == Void {
    let rp = CancellablePromise(when(fulfilled: asThenables(promises)))
    for p in promises {
        rp.appendCancelContext(from: p)
    }
    return rp
}

/**
 Wait for all cancellable promises in a set to fulfill.

 - Note: by convention the cancellable 'when' functions should not have a 'cancellable' prefix, however the prefix is necessary due to a compiler bug exemplified by the following:
 
     ````
     This works fine:
       1  func hi(_: String...) { }
       2  func hi(_: String, _: String) { }
       3  hi("hi", "there")

     This does not compile:
       1  func hi(_: String...) { }
       2  func hi(_: String, _: String) { }
       3  func hi(_: Int...) { }
       4  func hi(_: Int, _: Int) { }
       5
       6  hi("hi", "there")  // Ambiguous use of 'hi' (lines 1 & 2 are candidates)
       7  hi(1, 2)           // Ambiguous use of 'hi' (lines 3 & 4 are candidates)
     ````
 
  - SeeAlso: `when(fulfilled:,_:)`
*/
public func cancellableWhen<U: CancellableThenable, V: CancellableThenable>(fulfilled pu: U, _ pv: V) -> CancellablePromise<(U.U.T, V.U.T)> {
    return when(fulfilled: [pu.asVoid(), pv.asVoid()]).map(on: nil) { (pu.value!, pv.value!) }
}

/// Wait for all cancellable promises in a set to fulfill.
/// - SeeAlso: `when(fulfilled:,_:)`
public func cancellableWhen<U: CancellableThenable, V: CancellableThenable, W: CancellableThenable>(fulfilled pu: U, _ pv: V, _ pw: W) -> CancellablePromise<(U.U.T, V.U.T, W.U.T)> {
    return when(fulfilled: [pu.asVoid(), pv.asVoid(), pw.asVoid()]).map(on: nil) { (pu.value!, pv.value!, pw.value!) }
}

/// Wait for all cancellable promises in a set to fulfill.
/// - SeeAlso: `when(fulfilled:,_:)`
public func cancellableWhen<U: CancellableThenable, V: CancellableThenable, W: CancellableThenable, X: CancellableThenable>(fulfilled pu: U, _ pv: V, _ pw: W, _ px: X) -> CancellablePromise<(U.U.T, V.U.T, W.U.T, X.U.T)> {
    return when(fulfilled: [pu.asVoid(), pv.asVoid(), pw.asVoid(), px.asVoid()]).map(on: nil) { (pu.value!, pv.value!, pw.value!, px.value!) }
}

/// Wait for all cancellable promises in a set to fulfill.
/// - SeeAlso: `when(fulfilled:,_:)`
public func cancellableWhen<U: CancellableThenable, V: CancellableThenable, W: CancellableThenable, X: CancellableThenable, Y: CancellableThenable>(fulfilled pu: U, _ pv: V, _ pw: W, _ px: X, _ py: Y) -> CancellablePromise<(U.U.T, V.U.T, W.U.T, X.U.T, Y.U.T)> {
    return when(fulfilled: [pu.asVoid(), pv.asVoid(), pw.asVoid(), px.asVoid(), py.asVoid()]).map(on: nil) { (pu.value!, pv.value!, pw.value!, px.value!, py.value!) }
}

/**
 Generate cancellable promises at a limited rate and wait for all to fulfill.  Call `cancel` on the returned promise to cancel all currently pending promises.

 For example:
 
     func downloadFile(url: URL) -> CancellablePromise<Data> {
         // …
     }
 
     let urls: [URL] = /*…*/
     let urlGenerator = urls.makeIterator()

     let generator = AnyIterator<CancellablePromise<Data>> {
         guard url = urlGenerator.next() else {
             return nil
         }
         return downloadFile(url)
     }

     let promise = when(generator, concurrently: 3).done { datas in
         // …
     }
 
     // …
 
     promise.cancel()

 
 No more than three downloads will occur simultaneously.

 - Note: The generator is called *serially* on a *background* queue.
 - Warning: Refer to the warnings on `when(fulfilled:)`
 - Parameter promiseGenerator: Generator of promises.
 - Parameter cancel: Optional cancel context, overrides the default context.
 - Returns: A new promise that resolves when all the provided promises fulfill or one of the provided promises rejects.
 - SeeAlso: `when(resolved:)`
 */
public func when<It: IteratorProtocol>(fulfilled promiseIterator: It, concurrently: Int) -> CancellablePromise<[It.Element.U.T]> where It.Element: CancellableThenable {
    guard concurrently > 0 else {
        return CancellablePromise(error: PMKError.badInput)
    }
    
    var pi = promiseIterator
    var generatedPromises: [CancellablePromise<It.Element.U.T>] = []
    var rootPromise: CancellablePromise<[It.Element.U.T]>!
    
    let generator = AnyIterator<Promise<It.Element.U.T>> {
        guard let promise = pi.next() as? CancellablePromise<It.Element.U.T> else {
            return nil
        }
        if let root = rootPromise {
            root.appendCancelContext(from: promise)
        } else {
            generatedPromises.append(promise)
        }
        return promise.promise
    }
    
    rootPromise = CancellablePromise(when(fulfilled: generator, concurrently: concurrently))
    for p in generatedPromises {
        rootPromise.appendCancelContext(from: p)
    }
    return rootPromise
}

/**
 Waits on all provided cancellable promises.

 `when(fulfilled:)` rejects as soon as one of the provided promises rejects. `when(resolved:)` waits on all provided promises and *never* rejects.  When cancelled, all promises will attempt to be cancelled and those that are successfully cancelled will have a result of
 PMKError.cancelled.

     let p = when(resolved: promise1, promise2, promise3, cancel: context).then { results in
         for result in results where case .fulfilled(let value) {
            //…
         }
     }.catch { error in
         // invalid! Never rejects
     }
 
     //…

     p.cancel()
 
 - Returns: A new promise that resolves once all the provided promises resolve. The array is ordered the same as the input, ie. the result order is *not* resolution order.
 - Note: Any promises that error are implicitly consumed.
 - Remark: Doesn't take CancellableThenable due to protocol associatedtype paradox
*/
public func when<T>(resolved promises: CancellablePromise<T>...) -> CancellablePromise<[Result<T, Error>]> {
    return when(resolved: promises)
}

/// Waits on all provided cancellable promises.
/// - SeeAlso: `when(resolved:)`
public func when<T>(resolved promises: [CancellablePromise<T>]) -> CancellablePromise<[Result<T, Error>]> {
    let rp = CancellablePromise(when(resolved: asPromises(promises)))
    for p in promises {
        rp.appendCancelContext(from: p)
    }
    return rp
}

func asThenables<V: CancellableThenable>(_ cancellableThenables: [V]) -> [V.U] {
    var thenables: [V.U] = []
    for ct in cancellableThenables {
        thenables.append(ct.thenable)
    }
    return thenables
}

func asPromises<T>(_ cancellablePromises: [CancellablePromise<T>]) -> [Promise<T>] {
    var promises = [Promise<T>]()
    for cp in cancellablePromises {
        promises.append(cp.promise)
    }
    return promises
}
