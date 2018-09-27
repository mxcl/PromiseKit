import Foundation
import Dispatch

private func _when<U: Thenable>(_ thenables: [U]) -> Promise<Void> {
    var countdown = thenables.count
    guard countdown > 0 else {
        return .value(Void())
    }

    let rp = Promise<Void>(.pending)

#if PMKDisableProgress || os(Linux)
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
                case .rejected(let error):
                    if rp.isPending {
                        progress.completedUnitCount = progress.totalUnitCount
                        rp.box.seal(.rejected(error))
                    }
                case .fulfilled:
                    guard rp.isPending else { return }
                    progress.completedUnitCount += 1
                    countdown -= 1
                    if countdown == 0 {
                        rp.box.seal(.fulfilled(()))
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
 - Parameter promiseGenerator: Generator of promises.
 - Returns: A new promise that resolves when all the provided promises fulfill or one of the provided promises rejects.
 - SeeAlso: `when(resolved:)`
 */

public func when<It: IteratorProtocol>(fulfilled promiseIterator: It, concurrently: Int) -> Promise<[It.Element.T]> where It.Element: Thenable {

    guard concurrently > 0 else {
        return Promise(error: PMKError.badInput)
    }

    var generator = promiseIterator
    var root = Promise<[It.Element.T]>.pending()
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

        var index: Int!
        var promise: It.Element!

        barrier.sync(flags: .barrier) {
            guard let next = generator.next() else { return }

            promise = next
            index = promises.count

            pendingPromises += 1
            promises.append(next)
        }

        func testDone() {
            barrier.sync {
                if pendingPromises == 0 {
                  #if !swift(>=3.3) || (swift(>=4) && !swift(>=4.1))
                    root.resolver.fulfill(promises.flatMap{ $0.value })
                  #else
                    root.resolver.fulfill(promises.compactMap{ $0.value })
                  #endif
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
            case .fulfilled:
                dequeue()
                testDone()
            case .rejected(let error):
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
         for result in results where case .fulfilled(let value) {
            //…
         }
     }.catch { error in
         // invalid! Never rejects
     }

 - Returns: A new promise that resolves once all the provided promises resolve. The array is ordered the same as the input, ie. the result order is *not* resolution order.
 - Note: we do not provide tuple variants for `when(resolved:)` but will accept a pull-request
 - Remark: Doesn't take Thenable due to protocol `associatedtype` paradox
*/
public func when<T>(resolved promises: Promise<T>...) -> Guarantee<[Result<T>]> {
    return when(resolved: promises)
}

/// - See: `when(resolved: Promise<T>...)`
public func when<T>(resolved promises: [Promise<T>]) -> Guarantee<[Result<T>]> {
    guard !promises.isEmpty else {
        return .value([])
    }

    var countdown = promises.count
    let barrier = DispatchQueue(label: "org.promisekit.barrier.join", attributes: .concurrent)

    let rg = Guarantee<[Result<T>]>(.pending)
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

/// Waits on all provided Guarantees.
public func when(_ guarantees: Guarantee<Void>...) -> Guarantee<Void> {
    return when(guarantees: guarantees)
}

// Waits on all provided Guarantees.
public func when(guarantees: [Guarantee<Void>]) -> Guarantee<Void> {
    return when(fulfilled: guarantees).recover{ _ in }.asVoid()
}
