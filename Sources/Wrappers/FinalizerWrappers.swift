import Dispatch

extension PMKCascadingFinalizer {
    
    /// Set a default Dispatcher for the chain. Within the chain, this Dispatcher will remain the
    /// default until you change it, even if you dispatch individual closures to other Dispatchers.
    ///
    /// - Parameter on: The new default queue. Use `.default` to return to normal dispatching.
    /// - Parameter flags: `DispatchWorkItemFlags` to be applied when dispatching.
    
    func dispatch(on: DispatchQueue?, flags: DispatchWorkItemFlags? = nil) -> PMKCascadingFinalizer {
        let dispatcher = on.convertToDispatcher(flags: flags)
        return dispatch(on: dispatcher)
    }
}

extension CancellableCascadingFinalizer {
    
    /// Set a default Dispatcher for the chain. Within the chain, this Dispatcher will remain the
    /// default until you change it, even if you dispatch individual closures to other Dispatchers.
    ///
    /// - Parameter on: The new default queue. Use `.default` to return to normal dispatching.
    /// - Parameter flags: `DispatchWorkItemFlags` to be applied when dispatching.
    
    func dispatch(on: DispatchQueue?, flags: DispatchWorkItemFlags? = nil) -> CancellableCascadingFinalizer {
        let dispatcher = on.convertToDispatcher(flags: flags)
        return dispatch(on: dispatcher)
    }
}
