public struct Sealant<T> {
    public let resolve: (Result<T>) -> Void

    init(resolve body: @escaping (Result<T>) -> Void) {
        resolve = body
    }

    public func fulfill(_ value: T) {
        resolve(.fulfilled(value))
    }

    public func reject(_ error: Error) {
        resolve(.rejected(error))
    }

    /**
     This variant of resolve is convenient when wrapping asynchronous systems that
     use common patterns. For example:

         func fetchImage() -> Promise<UIImage> {
             return Promise { API.fetchImage(withCompletion: $0.resolve) }
         }

     Where:

         struct API {
             func fetchImage(withCompletion: (UIImage?, Error?) -> Void) {
                 // you or a third party provided this implementation
             }
         }
     */
    public func resolve(value: T?, error: Error?) {
        if let error = error {
            reject(error)
        } else if let value = value {
            fulfill(value)
        } else {
            reject(PMKError.invalidCallingConvention)
        }
    }

    /**
     This variant of resolve is convenient when wrapping asynchronous systems that
     use common patterns. For example:

         func fetch() -> Promise<FetchResult> {
             return Promise { API.fetch(withCompletion: $0.resolve) }
         }

     Where:

         enum FetchResult { /*…*/ }

         struct API {
             func fetchImage(withCompletion: (FetchResult, Error?) -> Void) {
                 // you or a third party provided this implementation
             }
         }

     - Note: This implies the `FetchResult` enum has an error `case`, which you
     thus lose. If you need to access this value you should handle the completion
     handler yourself.
     */
    public func resolve(value: T, error: Error?) {
        if let error = error {
            reject(error)
        } else {
            fulfill(value)
        }
    }

    /**
     This variant of resolve is provided so our initializer works, *even* if
     the API you are wrapping got the calling convention for completion handlers
     inverted.

         func fetchImage() -> Promise<UIImage> {
             return Promise { API.fetchImage(withCompletion: $0.resolve) }
         }

     Where:

         func fetchImage(withCompletion: (Error?, UIImage?) -> Void) {
             // you or a third party provided this implementation
         }

     */
    public func resolve(error: Error?, value: T?) {
        resolve(value: value, error: error)
    }
}


public func adapter<T, U>(_ seal: Sealant<(T, U)>) -> (T?, U?, Error?) -> Void {
    return { t, u, e in
        if let t = t, let u = u {
            seal.fulfill(t, u)
        } else if let e = e {
            seal.reject(e)
        } else {
            seal.reject(PMKError.invalidCallingConvention)
        }
    }
}
