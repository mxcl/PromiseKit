import Dispatch

public extension _PMKSharedWrappers {
    
    /**
     The provided closure executes when this promise resolves, whether it rejects or not.
     
         firstly {
             UIApplication.shared.networkActivityIndicatorVisible = true
         }.done {
             //…
         }.ensure {
             UIApplication.shared.networkActivityIndicatorVisible = false
         }.catch {
             //…
         }
     
     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter flags: `DispatchWorkItemFlags` to be applied when dispatching.
     - Parameter body: The closure that executes when this promise resolves.
     - Returns: A new promise, resolved with this promise’s resolution.
     */
    func ensure(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ body: @escaping () -> Void) -> BaseOfT {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.return, flags: flags)
        return ensure(on: dispatcher, body)
    }

    /**
     The provided closure executes when this promise resolves, whether it rejects or not.
     The chain waits on the returned `Guarantee<Void>`.

         firstly {
             setup()
         }.done {
             //…
         }.ensureThen {
             teardown()
         }.catch {
             //…
         }

     - Parameter on: The queue to which the provided closure dispatches.
     - Parameter flags: `DispatchWorkItemFlags` to be applied when dispatching.
     - Parameter body: The closure that executes when this promise resolves.
     - Returns: A new promise, resolved with this promise’s resolution.
     */
    func ensureThen(on: DispatchQueue? = .pmkDefault, flags: DispatchWorkItemFlags? = nil, _ body: @escaping () -> VoidReturn) -> BaseOfT {
        let dispatcher = selectDispatcher(given: on, configured: conf.D.return, flags: flags)
        return ensureThen(on: dispatcher, body)
    }
}
