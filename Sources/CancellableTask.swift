import Dispatch

/**
 Use this protocol to define cancellable tasks for CancellablePromise.
 */
public protocol Cancellable {
    /// Cancel the associated task
    func cancel()
    
    /// `true` if the task was successfully cancelled, `false` otherwise
    var isCancelled: Bool { get }
}
