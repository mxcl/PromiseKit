import Foundation
import Dispatch

// MARK: - when(fulfilled:) array

private func _when<TH: Thenable>(_ thenables: [TH]) -> Promise<Void> {
    guard !thenables.isEmpty else {
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
    var countdown = thenables.count

    for promise in thenables {
        promise.pipe { result in
            barrier.sync(flags: .barrier) {
                switch result {
                case .failure(let error):
                    guard rp.isPending else { return }
                    progress.completedUnitCount = progress.totalUnitCount
                    rp.box.seal(.failure(error))
                case .success:
                    guard rp.isPending else { return }
                    progress.completedUnitCount += 1
                    countdown -= 1
                    guard countdown == 0 else { return }
                    rp.box.seal(.success(()))
                }
            }
        }
    }

    return rp
}

/** Wait for all provided thenables to fulfill. You can use either an array of `Promise`'s or an array of `Guarantee`'s.
 
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

 - Note: If *any* of the provided thenables rejects, the returned promise is immediately rejected with that error.
 - Warning: In the event of rejection the other thenables will continue to resolve. `Guarantee`'s will resolve and `Promise`'s, will either fulfill or reject. This is the right pattern for `getter` style asynchronous tasks, but often for `setter` tasks (eg. storing data on a server), you most likely will need to wait on all tasks and then act based on which have succeeded and which have failed, in such situations use `when(resolved:)`.
 - Parameter fulfilled: The thenables upon which to wait before the returned promise resolves.
 - Returns: A new promise that resolves when all the provided thenables fulfill or one of the thenables rejects.
 - Note: `when(fulfilled:)` provides `NSProgress`.
 - Note: Provided thenables must be of the same concrete type and have the same associated type `T` as type of their wrapped values. Otherwise use tuple overloads.
 - SeeAlso: `when(resolved:)`
*/
public func when<TH: Thenable>(fulfilled thenables: [TH]) -> Promise<[TH.T]> {
    return _when(thenables).map(on: nil) { thenables.map{ $0.value! } }
}

/** Wait for all provided `Void` thenables to fulfill. You can use either an array of `Promise`'s or an array of `Guarantee`'s.
 
 Convenience function that returns `Promise<Void>` for `Void` thenables.
 - SeeAlso: when(fulfilled:)
 - SeeAlso: when(resolved:)
*/
public func when<TH: Thenable>(fulfilled thenables: [TH]) -> Promise<Void> where TH.T == Void {
    return _when(thenables)
}

// THIS MAKES UNAMBIGUOUS USAGES DUE TO TUPLE ARITY FUNCTIONS
//public func when<TH: Thenable>(fulfilled thenables: TH...) -> Promise<[TH.T]> {
//    return _when(thenables)
//}

// MARK: - when(fulfilled:) tuples arity

/** Wait for all provided thenables to fulfill. You can mix `Promise`'s and `Guarantee`'s.
*/
public func when<TH1: Thenable, TH2: Thenable>(fulfilled th1: TH1, _ th2: TH2) -> Promise<(TH1.T, TH2.T)> {
    return _when([th1.asVoid(), th2.asVoid()]).map(on: nil) { (th1.value!, th2.value!) }
}

/** Wait for all provided thenables to fulfill. You can mix `Promise`'s and `Guarantee`'s.
 */
public func when<TH1: Thenable, TH2: Thenable, TH3: Thenable>(fulfilled th1: TH1, _ th2: TH2, _ th3: TH3) -> Promise<(TH1.T, TH2.T, TH3.T)> {
    return _when([th1.asVoid(), th2.asVoid(), th3.asVoid()]).map(on: nil) { (th1.value!, th2.value!, th3.value!) }
}

/** Wait for all provided thenables to fulfill. You can mix `Promise`'s and `Guarantee`'s.
 */
public func when<TH1: Thenable, TH2: Thenable, TH3: Thenable, TH4: Thenable>(fulfilled th1: TH1, _ th2: TH2, _ th3: TH3, _ th4: TH4) -> Promise<(TH1.T, TH2.T, TH3.T, TH4.T)> {
    return _when([th1.asVoid(), th2.asVoid(), th3.asVoid(), th4.asVoid()]).map(on: nil) { (th1.value!, th2.value!, th3.value!, th4.value!) }
}

/** Wait for all provided thenables to fulfill. You can mix `Promise`'s and `Guarantee`'s.
 */
public func when<TH1: Thenable, TH2: Thenable, TH3: Thenable, TH4: Thenable, TH5: Thenable>(fulfilled th1: TH1, _ th2: TH2, _ th3: TH3, _ th4: TH4, _ th5: TH5) -> Promise<(TH1.T, TH2.T, TH3.T, TH4.T, TH5.T)> {
    return _when([th1.asVoid(), th2.asVoid(), th3.asVoid(), th4.asVoid(), th5.asVoid()]).map(on: nil) { (th1.value!, th2.value!, th3.value!, th4.value!, th5.value!) }
}

/** Wait for all provided thenables to fulfill. You can mix `Promise`'s and `Guarantee`'s.
 */
public func when<TH1: Thenable, TH2: Thenable, TH3: Thenable, TH4: Thenable, TH5: Thenable, TH6: Thenable>(fulfilled th1: TH1, _ th2: TH2, _ th3: TH3, _ th4: TH4, _ th5: TH5, _ th6: TH6) -> Promise<(TH1.T, TH2.T, TH3.T, TH4.T, TH5.T, TH6.T)> {
    return _when([th1.asVoid(), th2.asVoid(), th3.asVoid(), th4.asVoid(), th5.asVoid(), th6.asVoid()]).map(on: nil) { (th1.value!, th2.value!, th3.value!, th4.value!, th5.value!, th6.value!) }
}

/** Wait for all provided thenables to fulfill. You can mix `Promise`'s and `Guarantee`'s.
 */
public func when<TH1: Thenable, TH2: Thenable, TH3: Thenable, TH4: Thenable, TH5: Thenable, TH6: Thenable, TH7: Thenable>(fulfilled th1: TH1, _ th2: TH2, _ th3: TH3, _ th4: TH4, _ th5: TH5, _ th6: TH6, _ th7: TH7) -> Promise<(TH1.T, TH2.T, TH3.T, TH4.T, TH5.T, TH6.T, TH7.T)> {
    return _when([th1.asVoid(), th2.asVoid(), th3.asVoid(), th4.asVoid(), th5.asVoid(), th6.asVoid(), th7.asVoid()]).map(on: nil) { (th1.value!, th2.value!, th3.value!, th4.value!, th5.value!, th6.value!, th7.value!) }
}

/** Wait for all provided thenables to fulfill. You can mix `Promise`'s and `Guarantee`'s.
 */
public func when<TH1: Thenable, TH2: Thenable, TH3: Thenable, TH4: Thenable, TH5: Thenable, TH6: Thenable, TH7: Thenable, TH8: Thenable>(fulfilled th1: TH1, _ th2: TH2, _ th3: TH3, _ th4: TH4, _ th5: TH5, _ th6: TH6, _ th7: TH7, _ th8: TH8) -> Promise<(TH1.T, TH2.T, TH3.T, TH4.T, TH5.T, TH6.T, TH7.T, TH8.T)> {
    return _when([th1.asVoid(), th2.asVoid(), th3.asVoid(), th4.asVoid(), th5.asVoid(), th6.asVoid(), th7.asVoid(), th8.asVoid()]).map(on: nil) { (th1.value!, th2.value!, th3.value!, th4.value!, th5.value!, th6.value!, th7.value!, th8.value!) }
}

/** Wait for all provided thenables to fulfill. You can mix `Promise`'s and `Guarantee`'s.
 */
public func when<TH1: Thenable, TH2: Thenable, TH3: Thenable, TH4: Thenable, TH5: Thenable, TH6: Thenable, TH7: Thenable, TH8: Thenable, TH9: Thenable>(fulfilled th1: TH1, _ th2: TH2, _ th3: TH3, _ th4: TH4, _ th5: TH5, _ th6: TH6, _ th7: TH7, _ th8: TH8, _ th9: TH9) -> Promise<(TH1.T, TH2.T, TH3.T, TH4.T, TH5.T, TH6.T, TH7.T, TH8.T, TH9.T)> {
    return _when([th1.asVoid(), th2.asVoid(), th3.asVoid(), th4.asVoid(), th5.asVoid(), th6.asVoid(), th7.asVoid(), th8.asVoid(), th9.asVoid()]).map(on: nil) { (th1.value!, th2.value!, th3.value!, th4.value!, th5.value!, th6.value!, th7.value!, th8.value!, th9.value!) }
}

// MARK: - when(fulfilled:) iterator

/** Generate thenables at a limited rate and wait for all to fulfill.

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

     when(generator, concurrently: 3).done { datas in
         // ...
     }
 
 No more than three downloads will occur simultaneously.

 - Note: The generator is called *serially* on a *background* queue.
 - Warning: Refer to the warnings on `when(fulfilled:)`
 - Parameter fulfilled: Generator of thenables.
 - Returns: A new promise that resolves when all the provided thenables fulfill or one of the provided thenables rejects.
 - SeeAlso: `when(fulfilled:)`
 */
public func when<It: IteratorProtocol>(fulfilled iterator: It, concurrently: Int) -> Promise<[It.Element.T]> where It.Element: Thenable {
    guard concurrently > 0 else {
        return Promise(error: PMKError.badInput)
    }

    var generator = iterator
    let root = Promise<[It.Element.T]>.pending()
    var pendingPromises = 0
    var promises: [It.Element] = []
    let barrier = DispatchQueue(label: "org.promisekit.barrier.when", attributes: [.concurrent])

    func dequeue() {
        guard root.promise.isPending else { return } // don’t continue dequeueing if root has been rejected
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
                guard pendingPromises == 0 else { return }
                root.resolver.fulfill(promises.compactMap{ $0.value })
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

// MARK: - when(resolved:) array

private func _when<TH: Thenable>(resolved thenables: [TH]) -> Guarantee<Void> {
    guard !thenables.isEmpty else {
        return .value(Void())
    }
    var countdown = thenables.count
    let barrier = DispatchQueue(label: "org.promisekit.barrier.join", attributes: .concurrent)
    
    let rg = Guarantee<Void>(.pending)
    for thenable in thenables {
        thenable.pipe { result in
            barrier.sync(flags: .barrier) {
                countdown -= 1
            }
            barrier.sync {
                guard countdown == 0 else { return }
                rg.box.seal(Void())
            }
        }
    }
    return rg
}

/** Wait for all provided thenables to resolve. You can use either an array of `Promise`'s or an array of `Guarantee`'s.

 `when(fulfilled:)` rejects as soon as one of the provided thenables rejects. `when(resolved:)` waits on all provided thenables whatever their result, and then provides an array of corresponding results so you can inspect each one individually. As a consequence this function returns a `Guarantee`, ie. errors are lifted from the individual thenables into the results array of the returned `Guarantee`.

 For example:
 
     when(resolved: promise1, promise2, promise3).then { results in
         for result in results where case .fulfilled(let value) {
            //…
         }
     }.catch { error in
         // invalid! Never rejects
     }
 
 - Note: Provided thenables must be of the same concrete type and have the same associated type `R` as type of their results. Otherwise use tuple overloads.
 - Returns: A new guarantee that resolves once all the provided thenables resolve. The array is ordered the same as the input, ie. the result order is *not* resolution order.
*/
public func when<TH: Thenable>(resolved thenables: [TH]) -> Guarantee<[TH.R]> {
    return _when(resolved: thenables).map(on: nil) { thenables.map{ $0.result! } }
}

/** Wait for all provided `Void` thenables to resolve. You can use either an array of `Promise`'s or an array of `Guarantee`'s.
 
 Convenience function that returns `Promise<Void>` for `Void` thenables.
 - SeeAlso: when(fulfilled:)
 - SeeAlso: when(resolved:)
 */
public func when<TH: Thenable>(resolved thenables: [TH]) -> Guarantee<Void> where TH.T == Void {
    return _when(resolved: thenables)
}

// THIS MAKES UNAMBIGUOUS USAGES DUE TO TUPLE ARITY FUNCTIONS
//public func when<TH: Thenable>(resolved thenables: TH...) -> Guarantee<[TH.R]> {
//    return _when(resolved: thenables)
//}

// MARK: - when(resolved:) tuples arity

/** Wait for all provided thenables to resolve. You can mix `Promise`'s and `Guarantee`'s.
 */
public func when<TH1: Thenable, TH2: Thenable>(resolved th1: TH1, _ th2: TH2) -> Guarantee<(TH1.R, TH2.R)> {
    return _when(resolved: [th1.asVoid(), th2.asVoid()]).map(on: nil) { (th1.result!, th2.result!) }
}

/** Wait for all provided thenables to resolve. You can mix `Promise`'s and `Guarantee`'s.
 */
public func when<TH1: Thenable, TH2: Thenable, TH3: Thenable>(resolved th1: TH1, _ th2: TH2, _ th3: TH3) -> Guarantee<(TH1.R, TH2.R, TH3.R)> {
    return _when(resolved: [th1.asVoid(), th2.asVoid(), th3.asVoid()]).map(on: nil) { (th1.result!, th2.result!, th3.result!) }
}

/** Wait for all provided thenables to resolve. You can mix `Promise`'s and `Guarantee`'s.
 */
public func when<TH1: Thenable, TH2: Thenable, TH3: Thenable, TH4: Thenable>(resolved th1: TH1, _ th2: TH2, _ th3: TH3, _ th4: TH4) -> Guarantee<(TH1.R, TH2.R, TH3.R, TH4.R)> {
    return _when(resolved: [th1.asVoid(), th2.asVoid(), th3.asVoid(), th4.asVoid()]).map(on: nil) { (th1.result!, th2.result!, th3.result!, th4.result!) }
}

/** Wait for all provided thenables to resolve. You can mix `Promise`'s and `Guarantee`'s.
 */
public func when<TH1: Thenable, TH2: Thenable, TH3: Thenable, TH4: Thenable, TH5: Thenable>(resolved th1: TH1, _ th2: TH2, _ th3: TH3, _ th4: TH4, _ th5: TH5) -> Guarantee<(TH1.R, TH2.R, TH3.R, TH4.R, TH5.R)> {
    return _when(resolved: [th1.asVoid(), th2.asVoid(), th3.asVoid(), th4.asVoid(), th5.asVoid()]).map(on: nil) { (th1.result!, th2.result!, th3.result!, th4.result!, th5.result!) }
}

/** Wait for all provided thenables to resolve. You can mix `Promise`'s and `Guarantee`'s.
 */
public func when<TH1: Thenable, TH2: Thenable, TH3: Thenable, TH4: Thenable, TH5: Thenable, TH6: Thenable>(resolved th1: TH1, _ th2: TH2, _ th3: TH3, _ th4: TH4, _ th5: TH5, _ th6: TH6) -> Guarantee<(TH1.R, TH2.R, TH3.R, TH4.R, TH5.R, TH6.R)> {
    return _when(resolved: [th1.asVoid(), th2.asVoid(), th3.asVoid(), th4.asVoid(), th5.asVoid(), th6.asVoid()]).map(on: nil) { (th1.result!, th2.result!, th3.result!, th4.result!, th5.result!, th6.result!) }
}

/** Wait for all provided thenables to resolve. You can mix `Promise`'s and `Guarantee`'s.
 */
public func when<TH1: Thenable, TH2: Thenable, TH3: Thenable, TH4: Thenable, TH5: Thenable, TH6: Thenable, TH7: Thenable>(resolved th1: TH1, _ th2: TH2, _ th3: TH3, _ th4: TH4, _ th5: TH5, _ th6: TH6, _ th7: TH7) -> Guarantee<(TH1.R, TH2.R, TH3.R, TH4.R, TH5.R, TH6.R, TH7.R)> {
    return _when(resolved: [th1.asVoid(), th2.asVoid(), th3.asVoid(), th4.asVoid(), th5.asVoid(), th6.asVoid(), th7.asVoid()]).map(on: nil) { (th1.result!, th2.result!, th3.result!, th4.result!, th5.result!, th6.result!, th7.result!) }
}

/** Wait for all provided thenables to resolve. You can mix `Promise`'s and `Guarantee`'s.
 */
public func when<TH1: Thenable, TH2: Thenable, TH3: Thenable, TH4: Thenable, TH5: Thenable, TH6: Thenable, TH7: Thenable, TH8: Thenable>(resolved th1: TH1, _ th2: TH2, _ th3: TH3, _ th4: TH4, _ th5: TH5, _ th6: TH6, _ th7: TH7, _ th8: TH8) -> Guarantee<(TH1.R, TH2.R, TH3.R, TH4.R, TH5.R, TH6.R, TH7.R, TH8.R)> {
    return _when(resolved: [th1.asVoid(), th2.asVoid(), th3.asVoid(), th4.asVoid(), th5.asVoid(), th6.asVoid(), th7.asVoid(), th8.asVoid()]).map(on: nil) { (th1.result!, th2.result!, th3.result!, th4.result!, th5.result!, th6.result!, th7.result!, th8.result!) }
}

/** Wait for all provided thenables to resolve. You can mix `Promise`'s and `Guarantee`'s.
 */
public func when<TH1: Thenable, TH2: Thenable, TH3: Thenable, TH4: Thenable, TH5: Thenable, TH6: Thenable, TH7: Thenable, TH8: Thenable, TH9: Thenable>(resolved th1: TH1, _ th2: TH2, _ th3: TH3, _ th4: TH4, _ th5: TH5, _ th6: TH6, _ th7: TH7, _ th8: TH8, _ th9: TH9) -> Guarantee<(TH1.R, TH2.R, TH3.R, TH4.R, TH5.R, TH6.R, TH7.R, TH8.R, TH9.R)> {
    return _when(resolved: [th1.asVoid(), th2.asVoid(), th3.asVoid(), th4.asVoid(), th5.asVoid(), th6.asVoid(), th7.asVoid(), th8.asVoid(), th9.asVoid()]).map(on: nil) { (th1.result!, th2.result!, th3.result!, th4.result!, th5.result!, th6.result!, th7.result!, th8.result!, th9.result!) }
}

// MARK: - when(resolved:) iterator

/** Generate thenables at a limited rate and wait for all to resolve.
 
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
- Parameter resolved: Generator of thenables.
- Returns: A new promise that resolves once all the provided thenables resolve. The array is ordered the same as the input, ie. the result order is *not* resolution order.
- SeeAlso: `when(resolved:)`
*/
public func when<It: IteratorProtocol>(resolved iterator: It, concurrently: Int) -> Guarantee<[It.Element.R]> where It.Element: Thenable {
    let concurrently = max(concurrently, 1)
    var generator = iterator
    let root = Guarantee<[It.Element.R]>.pending()
    var pendingPromises = 0
    var promises: [It.Element] = []
    let barrier = DispatchQueue(label: "org.promisekit.barrier.when", attributes: [.concurrent])

    func dequeue() {
        guard root.guarantee.isPending else { return } // don’t continue dequeueing if root has been rejected
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
                guard pendingPromises == 0 else { return }
                root.resolve(promises.compactMap { $0.result })
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

// MARK: - when(fulfilled:) array - cancellable

/** Wait for all cancellable thenables to fulfill.
 
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
 
 - Note: If *any* of the provided cancellable thenables rejects, the returned cancellable promise is immediately rejected with that error.
 - Warning: In the event of rejection the other thenables will continue to resolve. `Guarantee`'s will resolve and `Promise`'s, will either fulfill or reject. This is the right pattern for `getter` style asynchronous tasks, but often for `setter` tasks (eg. storing data on a server), you most likely will need to wait on all tasks and then act based on which have succeeded and which have failed, in such situations use `when(resolved:)`.
 - Parameter fulfilled: The cancellable thenables upon which to wait before the returned cancellable promise resolves.
 - Returns: A new cancellable promise that resolves when all the provided cancellable thenables fulfill or one of the provided cancellable thenables rejects.
 - Note: `when(fulfilled:)` provides `NSProgress`.
 - Note: Provided cancellable thenables must be of the same concrete type and have the same associated type `T` as type of their wrapped thenable values. Otherwise use tuple overloads.
 - SeeAlso: `when(resolved:)`
*/
public func when<CT: CancellableThenable>(fulfilled thenables: [CT]) -> CancellablePromise<[CT.U.T]> {
    let rp = CancellablePromise(when(fulfilled: asThenables(thenables)))
    for t in thenables {
        rp.appendCancelContext(from: t)
    }
    return rp
}

/** Wait for all provided `Void` cancellable thenables to fulfill.
 
 Convenience function that returns `CancellablePromise<Void>` for `Void` cancellable thenables.
 - SeeAlso: when(fulfilled:)
 - SeeAlso: when(resolved:)
*/
public func when<CT: CancellableThenable>(fulfilled thenables: [CT]) -> CancellablePromise<Void> where CT.U.T == Void {
    let rp = CancellablePromise(when(fulfilled: asThenables(thenables)))
    for t in thenables {
        rp.appendCancelContext(from: t)
    }
    return rp
}

// THIS MAKES UNAMBIGUOUS USAGES DUE TO TUPLE ARITY FUNCTIONS
//public func when<CT: CancellableThenable>(fulfilled thenables: CT...) -> CancellablePromise<[CT.U.T]> {
//    let rp = CancellablePromise(when(fulfilled: asThenables(thenables)))
//    for t in thenables {
//        rp.appendCancelContext(from: t)
//    }
//    return rp
//}

// MARK: - when(fulfilled:) tuples arity - cancellable

/** Wait for all provided cancellable thenables to fulfill.
*/
public func when<CT1: CancellableThenable, CT2: CancellableThenable>(fulfilled ct1: CT1, _ ct2: CT2) -> CancellablePromise<(CT1.U.T, CT2.U.T)> {
    return when(fulfilled: [ct1.asVoid(), ct2.asVoid()]).map(on: nil) { (ct1.value!, ct2.value!) }
}

/** Wait for all provided cancellable thenables to fulfill.
 */
public func when<CT1: CancellableThenable, CT2: CancellableThenable, CT3: CancellableThenable>(fulfilled ct1: CT1, _ ct2: CT2, _ ct3: CT3) -> CancellablePromise<(CT1.U.T, CT2.U.T, CT3.U.T)> {
    return when(fulfilled: [ct1.asVoid(), ct2.asVoid(), ct3.asVoid()]).map(on: nil) { (ct1.value!, ct2.value!, ct3.value!) }
}

/** Wait for all provided cancellable thenables to fulfill.
 */
public func when<CT1: CancellableThenable, CT2: CancellableThenable, CT3: CancellableThenable, CT4: CancellableThenable>(fulfilled ct1: CT1, _ ct2: CT2, _ ct3: CT3, _ ct4: CT4) -> CancellablePromise<(CT1.U.T, CT2.U.T, CT3.U.T, CT4.U.T)> {
    return when(fulfilled: [ct1.asVoid(), ct2.asVoid(), ct3.asVoid(), ct4.asVoid()]).map(on: nil) { (ct1.value!, ct2.value!, ct3.value!, ct4.value!) }
}

/** Wait for all provided cancellable thenables to fulfill.
 */
public func when<CT1: CancellableThenable, CT2: CancellableThenable, CT3: CancellableThenable, CT4: CancellableThenable, CT5: CancellableThenable>(fulfilled ct1: CT1, _ ct2: CT2, _ ct3: CT3, _ ct4: CT4, _ ct5: CT5) -> CancellablePromise<(CT1.U.T, CT2.U.T, CT3.U.T, CT4.U.T, CT5.U.T)> {
    return when(fulfilled: [ct1.asVoid(), ct2.asVoid(), ct3.asVoid(), ct4.asVoid(), ct5.asVoid()]).map(on: nil) { (ct1.value!, ct2.value!, ct3.value!, ct4.value!, ct5.value!) }
}

/** Wait for all provided cancellable thenables to fulfill.
 */
public func when<CT1: CancellableThenable, CT2: CancellableThenable, CT3: CancellableThenable, CT4: CancellableThenable, CT5: CancellableThenable, CT6: CancellableThenable>(fulfilled ct1: CT1, _ ct2: CT2, _ ct3: CT3, _ ct4: CT4, _ ct5: CT5, _ ct6: CT6) -> CancellablePromise<(CT1.U.T, CT2.U.T, CT3.U.T, CT4.U.T, CT5.U.T, CT6.U.T)> {
    return when(fulfilled: [ct1.asVoid(), ct2.asVoid(), ct3.asVoid(), ct4.asVoid(), ct5.asVoid(), ct6.asVoid()]).map(on: nil) { (ct1.value!, ct2.value!, ct3.value!, ct4.value!, ct5.value!, ct6.value!) }
}

/** Wait for all provided cancellable thenables to fulfill.
 */
public func when<CT1: CancellableThenable, CT2: CancellableThenable, CT3: CancellableThenable, CT4: CancellableThenable, CT5: CancellableThenable, CT6: CancellableThenable, CT7: CancellableThenable>(fulfilled ct1: CT1, _ ct2: CT2, _ ct3: CT3, _ ct4: CT4, _ ct5: CT5, _ ct6: CT6, _ ct7: CT7) -> CancellablePromise<(CT1.U.T, CT2.U.T, CT3.U.T, CT4.U.T, CT5.U.T, CT6.U.T, CT7.U.T)> {
    return when(fulfilled: [ct1.asVoid(), ct2.asVoid(), ct3.asVoid(), ct4.asVoid(), ct5.asVoid(), ct6.asVoid(), ct7.asVoid()]).map(on: nil) { (ct1.value!, ct2.value!, ct3.value!, ct4.value!, ct5.value!, ct6.value!, ct7.value!) }
}

/** Wait for all provided cancellable thenables to fulfill.
 */
public func when<CT1: CancellableThenable, CT2: CancellableThenable, CT3: CancellableThenable, CT4: CancellableThenable, CT5: CancellableThenable, CT6: CancellableThenable, CT7: CancellableThenable, CT8: CancellableThenable>(fulfilled ct1: CT1, _ ct2: CT2, _ ct3: CT3, _ ct4: CT4, _ ct5: CT5, _ ct6: CT6, _ ct7: CT7, _ ct8: CT8) -> CancellablePromise<(CT1.U.T, CT2.U.T, CT3.U.T, CT4.U.T, CT5.U.T, CT6.U.T, CT7.U.T, CT8.U.T)> {
    return when(fulfilled: [ct1.asVoid(), ct2.asVoid(), ct3.asVoid(), ct4.asVoid(), ct5.asVoid(), ct6.asVoid(), ct7.asVoid(), ct8.asVoid()]).map(on: nil) { (ct1.value!, ct2.value!, ct3.value!, ct4.value!, ct5.value!, ct6.value!, ct7.value!, ct8.value!) }
}

/** Wait for all provided cancellable thenables to fulfill.
 */
public func when<CT1: CancellableThenable, CT2: CancellableThenable, CT3: CancellableThenable, CT4: CancellableThenable, CT5: CancellableThenable, CT6: CancellableThenable, CT7: CancellableThenable, CT8: CancellableThenable, CT9: CancellableThenable>(fulfilled ct1: CT1, _ ct2: CT2, _ ct3: CT3, _ ct4: CT4, _ ct5: CT5, _ ct6: CT6, _ ct7: CT7, _ ct8: CT8, _ ct9: CT9) -> CancellablePromise<(CT1.U.T, CT2.U.T, CT3.U.T, CT4.U.T, CT5.U.T, CT6.U.T, CT7.U.T, CT8.U.T, CT9.U.T)> {
    return when(fulfilled: [ct1.asVoid(), ct2.asVoid(), ct3.asVoid(), ct4.asVoid(), ct5.asVoid(), ct6.asVoid(), ct7.asVoid(), ct8.asVoid(), ct9.asVoid()]).map(on: nil) { (ct1.value!, ct2.value!, ct3.value!, ct4.value!, ct5.value!, ct6.value!, ct7.value!, ct8.value!, ct9.value!) }
}

// MARK: - when(fulfilled:) iterator - cancellable

/** Generate cancellable thenables at a limited rate and wait for all to fulfill.  Call `cancel` on the returned cancellable promise to cancel all currently pending cancellable thenables.
 
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
 - Parameter fulfilled: Generator of cancellable thenables.
 - Returns: A new cancellable promise that resolves when all the provided cancellable thenables fulfill or one of the provided cancellable thenables rejects.
 - SeeAlso: `when(fulfilled:)`
 */
public func when<It: IteratorProtocol>(fulfilled iterator: It, concurrently: Int) -> CancellablePromise<[It.Element.U.T]> where It.Element: CancellableThenable {
    guard concurrently > 0 else {
        return CancellablePromise(error: PMKError.badInput)
    }
    var pi = iterator
    var generatedPromises: [It.Element] = []
    var rootPromise: CancellablePromise<[It.Element.U.T]>!
    
    let generator = AnyIterator<It.Element.U> {
        guard let cancellableThenable = pi.next() else {
            return nil
        }
        if let root = rootPromise {
            root.appendCancelContext(from: cancellableThenable)
        } else {
            generatedPromises.append(cancellableThenable)
        }
        return cancellableThenable.thenable
    }
    
    rootPromise = CancellablePromise(when(fulfilled: generator, concurrently: concurrently))
    for p in generatedPromises {
        rootPromise.appendCancelContext(from: p)
    }
    return rootPromise
}

// MARK: - when(resolved:) array - cancellable

/** Wait for all provided cancellable thenables to resolve.
 
 `when(fulfilled:)` rejects as soon as one of the provided cancellable thenables rejects. `when(resolved:)` waits on all provided cancellable thenables and *never* rejects.  When cancelled, all thenables will attempt to be cancelled and those that are successfully cancelled will have a result of `PMKError.cancelled`.
 
 For example:
 
     let p = when(resolved: promise1, promise2, promise3, cancel: context).then { results in
         for result in results where case .fulfilled(let value) {
            //…
         }
     }.catch { error in
         // invalid! Never rejects
     }
 
     //…
     p.cancel()
 
 - Returns: A new cancellable promise that resolves once all the provided cancellable thenables resolve. The array is ordered the same as the input, ie. the result order is *not* resolution order.
 - Note: Any cancellable thenables that error out are implicitly consumed.
 - Note: Provided cancellable thenables must be of the same concrete type and have the same associated type `R` as type of their wrapped thenable results. Otherwise use tuple overloads.
 - SeeAlso: `when(resolved:)`
*/
public func when<CT: CancellableThenable>(resolved cancellableThenables: [CT]) -> CancellablePromise<[CT.U.R]> {
    let rp = CancellablePromise(when(resolved: asThenables(cancellableThenables)))
    for thenable in cancellableThenables {
        rp.appendCancelContext(from: thenable)
    }
    return rp
}

/** Wait for all provided `Void` cancellable thenables to resolve.
 
 Convenience function that returns `CancellablePromise<Void>` for `Void` cancellable thenables.
 - SeeAlso: when(fulfilled:)
 - SeeAlso: when(resolved:)
*/
public func when<CT: CancellableThenable>(resolved cancellableThenables: [CT]) -> CancellablePromise<Void> where CT.U.T == Void {
    let rp = CancellablePromise(when(resolved: asThenables(cancellableThenables)))
    for thenable in cancellableThenables {
        rp.appendCancelContext(from: thenable)
    }
    return rp
}

// THIS MAKES UNAMBIGUOUS USAGES DUE TO TUPLE ARITY FUNCTIONS
//public func when<CT: CancellableThenable>(resolved cancellableThenables: CT...) -> CancellablePromise<[CT.U.R]> {
//    return when(resolved: cancellableThenables)
//}

// MARK: - when(resolved:) tuples arity - cancellable

/** Wait for all provided cancellable thenables to resolve.
*/
public func when<CT1: CancellableThenable, CT2: CancellableThenable>(resolved ct1: CT1, _ ct2: CT2) -> CancellablePromise<(CT1.U.R, CT2.U.R)> {
    return when(resolved: [ct1.asVoid(), ct2.asVoid()]).map(on: nil) { (ct1.result!, ct2.result!) }
}

/** Wait for all provided cancellable thenables to resolve.
 */
public func when<CT1: CancellableThenable, CT2: CancellableThenable, CT3: CancellableThenable>(resolved ct1: CT1, _ ct2: CT2, _ ct3: CT3) -> CancellablePromise<(CT1.U.R, CT2.U.R, CT3.U.R)> {
    return when(resolved: [ct1.asVoid(), ct2.asVoid(), ct3.asVoid()]).map(on: nil) { (ct1.result!, ct2.result!, ct3.result!) }
}

/** Wait for all provided cancellable thenables to resolve.
 */
public func when<CT1: CancellableThenable, CT2: CancellableThenable, CT3: CancellableThenable, CT4: CancellableThenable>(resolved ct1: CT1, _ ct2: CT2, _ ct3: CT3, _ ct4: CT4) -> CancellablePromise<(CT1.U.R, CT2.U.R, CT3.U.R, CT4.U.R)> {
    return when(resolved: [ct1.asVoid(), ct2.asVoid(), ct3.asVoid(), ct4.asVoid()]).map(on: nil) { (ct1.result!, ct2.result!, ct3.result!, ct4.result!) }
}

/** Wait for all provided cancellable thenables to resolve.
 */
public func when<CT1: CancellableThenable, CT2: CancellableThenable, CT3: CancellableThenable, CT4: CancellableThenable, CT5: CancellableThenable>(resolved ct1: CT1, _ ct2: CT2, _ ct3: CT3, _ ct4: CT4, _ ct5: CT5) -> CancellablePromise<(CT1.U.R, CT2.U.R, CT3.U.R, CT4.U.R, CT5.U.R)> {
    return when(resolved: [ct1.asVoid(), ct2.asVoid(), ct3.asVoid(), ct4.asVoid(), ct5.asVoid()]).map(on: nil) { (ct1.result!, ct2.result!, ct3.result!, ct4.result!, ct5.result!) }
}

/** Wait for all provided cancellable thenables to resolve.
 */
public func when<CT1: CancellableThenable, CT2: CancellableThenable, CT3: CancellableThenable, CT4: CancellableThenable, CT5: CancellableThenable, CT6: CancellableThenable>(resolved ct1: CT1, _ ct2: CT2, _ ct3: CT3, _ ct4: CT4, _ ct5: CT5, _ ct6: CT6) -> CancellablePromise<(CT1.U.R, CT2.U.R, CT3.U.R, CT4.U.R, CT5.U.R, CT6.U.R)> {
    return when(resolved: [ct1.asVoid(), ct2.asVoid(), ct3.asVoid(), ct4.asVoid(), ct5.asVoid(), ct6.asVoid()]).map(on: nil) { (ct1.result!, ct2.result!, ct3.result!, ct4.result!, ct5.result!, ct6.result!) }
}

/** Wait for all provided cancellable thenables to resolve.
 */
public func when<CT1: CancellableThenable, CT2: CancellableThenable, CT3: CancellableThenable, CT4: CancellableThenable, CT5: CancellableThenable, CT6: CancellableThenable, CT7: CancellableThenable>(resolved ct1: CT1, _ ct2: CT2, _ ct3: CT3, _ ct4: CT4, _ ct5: CT5, _ ct6: CT6, _ ct7: CT7) -> CancellablePromise<(CT1.U.R, CT2.U.R, CT3.U.R, CT4.U.R, CT5.U.R, CT6.U.R, CT7.U.R)> {
    return when(resolved: [ct1.asVoid(), ct2.asVoid(), ct3.asVoid(), ct4.asVoid(), ct5.asVoid(), ct6.asVoid(), ct7.asVoid()]).map(on: nil) { (ct1.result!, ct2.result!, ct3.result!, ct4.result!, ct5.result!, ct6.result!, ct7.result!) }
}

/** Wait for all provided cancellable thenables to resolve.
 */
public func when<CT1: CancellableThenable, CT2: CancellableThenable, CT3: CancellableThenable, CT4: CancellableThenable, CT5: CancellableThenable, CT6: CancellableThenable, CT7: CancellableThenable, CT8: CancellableThenable>(resolved ct1: CT1, _ ct2: CT2, _ ct3: CT3, _ ct4: CT4, _ ct5: CT5, _ ct6: CT6, _ ct7: CT7, _ ct8: CT8) -> CancellablePromise<(CT1.U.R, CT2.U.R, CT3.U.R, CT4.U.R, CT5.U.R, CT6.U.R, CT7.U.R, CT8.U.R)> {
    return when(resolved: [ct1.asVoid(), ct2.asVoid(), ct3.asVoid(), ct4.asVoid(), ct5.asVoid(), ct6.asVoid(), ct7.asVoid(), ct8.asVoid()]).map(on: nil) { (ct1.result!, ct2.result!, ct3.result!, ct4.result!, ct5.result!, ct6.result!, ct7.result!, ct8.result!) }
}

/** Wait for all provided cancellable thenables to resolve.
 */
public func when<CT1: CancellableThenable, CT2: CancellableThenable, CT3: CancellableThenable, CT4: CancellableThenable, CT5: CancellableThenable, CT6: CancellableThenable, CT7: CancellableThenable, CT8: CancellableThenable, CT9: CancellableThenable>(resolved ct1: CT1, _ ct2: CT2, _ ct3: CT3, _ ct4: CT4, _ ct5: CT5, _ ct6: CT6, _ ct7: CT7, _ ct8: CT8, _ ct9: CT9) -> CancellablePromise<(CT1.U.R, CT2.U.R, CT3.U.R, CT4.U.R, CT5.U.R, CT6.U.R, CT7.U.R, CT8.U.R, CT9.U.R)> {
    return when(resolved: [ct1.asVoid(), ct2.asVoid(), ct3.asVoid(), ct4.asVoid(), ct5.asVoid(), ct6.asVoid(), ct7.asVoid(), ct8.asVoid(), ct9.asVoid()]).map(on: nil) { (ct1.result!, ct2.result!, ct3.result!, ct4.result!, ct5.result!, ct6.result!, ct7.result!, ct8.result!, ct9.result!) }
}

// MARK: - when(resolved:) iterator - cancellable

/** Generate cancellable thenables at a limited rate and wait for all to resolve.  Call `cancel` on the returned cancellable promise to cancel all currently pending cancellable thenables.
 
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
 - Parameter fulfilled: Generator of cancellable thenables.
 - Returns: A new cancellable promise that resolves when all the provided cancellable thenables fulfill or one of the provided cancellable thenables rejects.
 - SeeAlso: `when(fulfilled:)`
 */
public func when<It: IteratorProtocol>(resolved iterator: It, concurrently: Int) -> CancellablePromise<[It.Element.U.R]> where It.Element: CancellableThenable {
    guard concurrently > 0 else {
        return CancellablePromise(error: PMKError.badInput)
    }
    var pi = iterator
    var generatedPromises: [It.Element] = []
    var rootPromise: CancellablePromise<[It.Element.U.R]>!
    
    let generator = AnyIterator<It.Element.U> {
        guard let cancellableThenable = pi.next() else {
            return nil
        }
        if let root = rootPromise {
            root.appendCancelContext(from: cancellableThenable)
        } else {
            generatedPromises.append(cancellableThenable)
        }
        return cancellableThenable.thenable
    }
    
    rootPromise = CancellablePromise(when(resolved: generator, concurrently: concurrently))
    for p in generatedPromises {
        rootPromise.appendCancelContext(from: p)
    }
    return rootPromise
}
