import Dispatch

extension DispatchQueue {
    /**
     Submits a block for asynchronous execution on a dispatch queue.

         DispatchQueue.global().promise {
            try md5(input)
         }.then { md5 in
            //…
         }

     - Parameter body: The closure that resolves this promise.
     - Returns: A new promise resolved by the result of the provided closure.
     - SeeAlso: `DispatchQueue.async(group:qos:flags:execute:)`
     */
    public final func promise<ReturnType: Chainable>(group: DispatchGroup? = nil, qos: DispatchQoS = .default, flags: DispatchWorkItemFlags = [], execute body: @escaping () throws -> ReturnType) -> Promise<ReturnType.Wrapped> {

        return Promise { pipe in
            async(group: group, qos: qos, flags: flags) {
                do {
                    try body().pipe(to: pipe)
                } catch {
                    pipe.reject(error)
                }
            }
        }
    }

    /**
     The default queue for all handlers.

     Defaults to `DispatchQueue.main`.

     - Important: Must be set before *any* other PromiseKit function.
     - SeeAlso: `PMKDefaultDispatchQueue()`
     - SeeAlso: `PMKSetDefaultDispatchQueue()`
     */
    class public final var `default`: DispatchQueue {
        get {
            return __PMKDefaultDispatchQueue()
        }
        set {
            __PMKSetDefaultDispatchQueue(newValue)
        }
    }
}


extension DispatchQueue {

    /// prevent unecessary dipatching between thens that want the same queue
    @inline(__always)  // make backtraces somewhat more readable
    func maybe(async body: @escaping () -> Void) {
        let currentQueueLabel = String(cString: __dispatch_queue_get_label(nil))

        // strictly different queues can have the same label, but if
        // so whoever did so must intend for them to be used identically
        // otherwise they are violating the GCD contracts.
        if label == currentQueueLabel {
            body()
        } else {
            async(execute: body)
        }
    }
}
