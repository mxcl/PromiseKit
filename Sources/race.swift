
public func race<T>(promises: Promise<T>...) -> Promise<T> {
    return Promise(passthru: { resolve in
        for promise in promises {
            promise.pipe(resolve)
        }
    })
}
