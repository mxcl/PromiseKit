/**
 Returns a promise that fulfills when any of the provided promises
 resolve.
*/
public func race<T>(promises: Promise<T>...) -> Promise<(T, Int)> {
    return Promise { fulfill, reject in
        for (index, promise) in enumerate(promises) {
            promise.thenUnleashZalgo { value->() in
                fulfill(value, index)
            }
            promise.catch(reject)
        }
    }
}
