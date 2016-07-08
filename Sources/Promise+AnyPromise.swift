import class Dispatch.DispatchQueue

extension Promise {
    /**
     The provided closure is executed when this Promise is resolved.

     - Parameter on: The queue on which body should be executed.
     - Parameter body: The closure that is executed when this Promise is fulfilled.
     - Returns: A new promise that is resolved when the AnyPromise returned from the provided closure resolves. For example:

           NSURLSession.GET(url).then { (data: NSData) -> AnyPromise in
               //…
               return SCNetworkReachability()
           }.then { _ in
               //…
           }
     */
    public func then(on q: DispatchQueue = PMKDefaultDispatchQueue(), execute body: (T) throws -> AnyPromise) -> Promise<AnyObject?> {
        return Promise<AnyObject?> { resolve in
            state.then(on: q, else: resolve) { value in
                try body(value).state.pipe(resolve)
            }
        }
    }

    @available(*, unavailable, message: "unwrap the promise")
    public func then(on: DispatchQueue = PMKDefaultDispatchQueue(), execute body: (T) throws -> AnyPromise?) -> Promise<AnyObject?> { fatalError() }
}

/**
 `firstly` can make chains more readable.
*/
public func firstly(execute body: @noescape () throws -> AnyPromise) -> Promise<AnyObject?> {
    return Promise(sealant: { resolve in
        do {
            try body().state.pipe(resolve)
        } catch {
            resolve(Resolution(error))
        }
    })
}
