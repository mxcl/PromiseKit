import Foundation.NSProgress

private func when<T>(promises: [Promise<T>]) -> Promise<Void> {

    //TODO PMKFailingPromiseIndexKey

#if !PMKDisableProgress
    let progress = NSProgress(totalUnitCount: Int64(promises.count))
    progress.cancellable = false
    progress.pausable = false
#else
    var progress: (completedUnitCount: Int, totalUnitCount: Int) = (0, 0)
#endif
    var countdown = promises.count
    let barrier = dispatch_queue_create("org.promisekit.barrier.when", DISPATCH_QUEUE_CONCURRENT)

    return Promise { fulfill, reject in
        guard promises.count > 0 else { return fulfill() }

        for promise in promises {
            promise.pipe { resolution in
                guard progress.fractionCompleted < 1 else { return }

                dispatch_barrier_sync(barrier) {
                    switch resolution {
                    case .Rejected(let error):
                        progress.completedUnitCount = progress.totalUnitCount
                        reject(error)
                    case .Fulfilled:
                        progress.completedUnitCount++
                        if --countdown == 0 {
                            fulfill()
                        }
                    }
                }
            }
        }
    }
}

public func when<T>(promises: [Promise<T>]) -> Promise<[T]> {
    return when(promises).then(on: zalgo) { promises.map{ $0.value! } }
}

public func when<T>(promises: Promise<T>...) -> Promise<[T]> {
    return when(promises)
}

public func when(promises: Promise<Void>...) -> Promise<Void> {
    return when(promises)
}

public func when<U, V>(pu: Promise<U>, _ pv: Promise<V>) -> Promise<(U, V)> {
    return when(pu.asVoid(), pv.asVoid()).then(on: zalgo) { (pu.value!, pv.value!) }
}

public func when<U, V, X>(pu: Promise<U>, _ pv: Promise<V>, _ px: Promise<X>) -> Promise<(U, V, X)> {
    return when(pu.asVoid(), pv.asVoid(), px.asVoid()).then(on: zalgo) { (pu.value!, pv.value!, px.value!) }
}

@available(*, unavailable, message="Use `when`")
public func join<T>(promises: Promise<T>...) {}
