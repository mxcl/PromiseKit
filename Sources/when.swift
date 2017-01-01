#if os(Linux)
import Foundation
import Dispatch
#else
import class Foundation.Progress
#endif

private func _when<T>(_ promises: [Promise<T>]) -> Promise<Void> {
    guard !promises.isEmpty else {
        return Promise()
    }

    var countdown = promises.count
    let root = Promise<Void>._pending()

#if !PMKDisableProgress
#if os(Linux)
    let progress = NSProgress(totalUnitCount: Int64(promises.count))
    progress.cancellable = false
    progress.pausable = false
#else
    let progress = Progress(totalUnitCount: Int64(promises.count))
    progress.isCancellable = false
    progress.isPausable = false
#endif //Linux
#else
    var progress: (completedUnitCount: Int, totalUnitCount: Int) = (0, 0)
#endif
    
    let barrier = DispatchQueue(label: "org.promisekit.barrier.when", attributes: .concurrent)

    for promise in promises {
        promise.state.pipe { result in
            barrier.sync(flags: .barrier) {
                switch result {
                case .rejected(let error):
                    if root.promise.isPending {
                        progress.completedUnitCount = progress.totalUnitCount
                        root.resolve(.rejected(error))
                    }
                case .fulfilled:
                    guard root.promise.isPending else { return }
                    progress.completedUnitCount += 1
                    countdown -= 1
                    if countdown == 0 {
                        root.resolve(.fulfilled())
                    }
                }
            }
        }
    }

    return root.promise
}

/**
 Wait for all promises in a set to fulfill.

 For example:

     when(fulfilled: promise1, promise2).then { results in
         //…
     }.catch { error in
         switch error {
         case NSURLError.NoConnection:
             //…
         case CLError.NotAuthorized:
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
public func when<T>(fulfilled promises: [Promise<T>]) -> Promise<[T]> {
    return _when(promises).then(on: nil) { Promise(promises.map{ $0.value! }) }
}

/// - SeeAlso: `when(fulfilled:)`
public func when(fulfilled promises: Promise<Void>...) -> Promise<Void> {
    return _when(promises)
}

/// - SeeAlso: `when(fulfilled:)`
public func when(fulfilled promises: [Promise<Void>]) -> Promise<Void> {
    return _when(promises)
}

/// - SeeAlso: `when(fulfilled:)`
public func when<U, V>(fulfilled pu: Promise<U>, _ pv: Promise<V>) -> Promise<(U, V)> {
    return _when([pu.asVoid(), pv.asVoid()]).then(on: nil) { Promise(pu.value!, pv.value!) }
}

/// - SeeAlso: `when(fulfilled:)`
public func when<U, V, W>(fulfilled pu: Promise<U>, _ pv: Promise<V>, _ pw: Promise<W>) -> Promise<(U, V, W)> {
    return _when([pu.asVoid(), pv.asVoid(), pw.asVoid()]).then(on: nil) { Promise(pu.value!, pv.value!, pw.value!) }
}

/// - SeeAlso: `when(fulfilled:)`
public func when<U, V, W, X>(fulfilled pu: Promise<U>, _ pv: Promise<V>, _ pw: Promise<W>, _ px: Promise<X>) -> Promise<(U, V, W, X)> {
    return _when([pu.asVoid(), pv.asVoid(), pw.asVoid(), px.asVoid()]).then(on: nil) { Promise(pu.value!, pv.value!, pw.value!, px.value!) }
}

/// - SeeAlso: `when(fulfilled:)`
public func when<U, V, W, X, Y>(fulfilled pu: Promise<U>, _ pv: Promise<V>, _ pw: Promise<W>, _ px: Promise<X>, _ py: Promise<Y>) -> Promise<(U, V, W, X, Y)> {
    return _when([pu.asVoid(), pv.asVoid(), pw.asVoid(), px.asVoid(), py.asVoid()]).then(on: nil) { Promise(pu.value!, pv.value!, pw.value!, px.value!, py.value!) }
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

     when(generator, concurrently: 3).then { datum: [Data] -> Void in
         // ...
     }

 - Warning: Refer to the warnings on `when(fulfilled:)`
 - Parameter promiseGenerator: Generator of promises.
 - Returns: A new promise that resolves when all the provided promises fulfill or one of the provided promises rejects.
 - SeeAlso: `when(resolved:)`
 */

public func when<T, PromiseIterator: IteratorProtocol>(fulfilled promiseIterator: PromiseIterator, concurrently: Int) -> Promise<[T]> where PromiseIterator.Element == Promise<T> {

    guard concurrently > 0 else {
        return Promise(error: PMKError.badInput)
    }

    var generator = promiseIterator
    var root = Promise<[T]>._pending()
    var pendingPromises = 0
    var promises: [Promise<T>] = []

    let barrier = DispatchQueue(label: "org.promisekit.barrier.when", attributes: [.concurrent])

    func dequeue() {
        guard root.promise.isPending else { return }  // don’t continue dequeueing if root has been rejected

        var shouldDequeue = false
        barrier.sync {
            shouldDequeue = pendingPromises < concurrently
        }
        guard shouldDequeue else { return }

        var index: Int!
        var promise: Promise<T>!

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
                    root.resolve(.fulfilled(promises.flatMap{ $0.value }))
                }
            }
        }

        guard promise != nil else {
            return testDone()
        }

        promise.state.pipe { resolution in
            barrier.sync(flags: .barrier) {
                pendingPromises -= 1
            }

            switch resolution {
            case .fulfilled:
                dequeue()
                testDone()
            case .rejected(let error):
                root.resolve(.rejected(error))
            }
        }

        dequeue()
    }
        
    dequeue()

    return root.promise
}

/**
 Waits on all provided promises.

 `when(fulfilled:)` rejects as soon as one of the provided promises rejects. `when(resolved:)` waits on all provided promises and **never** rejects.

     when(resolved: promise1, promise2, promise3).then { results in
         for result in results where case .fulfilled(let value) {
            //…
         }
     }.catch { error in
         // invalid! Never rejects
     }

 - Returns: A new promise that resolves once all the provided promises resolve.
 - Warning: The returned promise can *not* be rejected.
 - Note: Any promises that error are implicitly consumed, your UnhandledErrorHandler will not be called.
*/
public func when<T>(resolved promises: Promise<T>...) -> Promise<[Result<T>]> {
    return when(resolved: promises)
}

/// - SeeAlso: when(resolved:)
public func when<T>(resolved promises: [Promise<T>]) -> Promise<[Result<T>]> {
    guard !promises.isEmpty else {
        return Promise([])
    }

    var countdown = promises.count
    let barrier = DispatchQueue(label: "org.promisekit.barrier.join", attributes: .concurrent)

    let (promise, resolve) = Promise<[Result<T>]>._pending()
    for promise in promises {
        promise.state.pipe { result in
            var done = false
            barrier.sync(flags: .barrier) {
                countdown -= 1
                done = countdown == 0
            }
            if done {
                let results = promises.map{ $0.state.get()! }
                resolve(.fulfilled(results))
            }
        }
    }
    return promise
}
