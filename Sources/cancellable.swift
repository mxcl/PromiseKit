/**
 Converts a Promise or Guarantee into a promise that can be cancelled.
 - Parameter thenable: The Thenable (Promise or Guarantee) to be made cancellable.
 - Returns: A CancellablePromise that is a cancellable variant of the given Promise or Guarantee.
 */
public func cancellable<U: Thenable>(_ thenable: U, cancelContext: CancelContext? = nil) -> CancellablePromise<U.T> {
    return CancellablePromise(thenable, cancelContext: cancelContext)
}
