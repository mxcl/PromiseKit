import Dispatch

public extension _PMKFinallyWrappers {
    /// `finally` is the same as `ensure`, but it is not chainable
    @discardableResult
    func finally(on: DispatchQueue? = .unspecified, flags: DispatchWorkItemFlags? = nil, _ body: @escaping () -> Void) -> FinallyReturn {
        let dispatcher = on.convertToDispatcher(flags: flags)
        return finally(on: dispatcher, body)
    }
}

