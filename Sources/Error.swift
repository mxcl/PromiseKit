import Foundation

public enum PMKError: Error {
    /**
     The completionHandler with form (T?, ErrorType?) was called with (nil, nil)
     This is invalid as per Cocoa/Apple calling conventions.
     */
    case invalidCallingConvention

    /**
     A handler returned its own promise. 99% of the time, this is likely a 
     programming error. It is also invalid per Promises/A+.
     */
    case returnedSelf

    /// Either `when(fulfilled:concurrently)` or `race()` was called with an empty array as input.
    case badInput
}

//////////////////////////////////////////////////////////// Cancellation

public protocol CancellableError: Error {
    var isCancelled: Bool { get }
}

#if !SWIFT_PACKAGE

private struct ErrorPair: Hashable {
    let domain: String
    let code: Int
    init(_ d: String, _ c: Int) {
        domain = d; code = c
    }
    var hashValue: Int {
        return "\(domain):\(code)".hashValue
    }
}

private func ==(lhs: ErrorPair, rhs: ErrorPair) -> Bool {
    return lhs.domain == rhs.domain && lhs.code == rhs.code
}

extension NSError {
    @objc public class func cancelledError() -> NSError {
        let info = [NSLocalizedDescriptionKey: "The operation was cancelled"]
        return NSError(domain: PMKErrorDomain, code: PMKOperationCancelled, userInfo: info)
    }

    /**
      - Warning: You must call this method before any promises in your application are rejected. Failure to ensure this may lead to concurrency crashes.
      - Warning: You must call this method on the main thread. Failure to do this may lead to concurrency crashes.
     */
    @objc public class func registerCancelledErrorDomain(_ domain: String, code: Int) {
        cancelledErrorIdentifiers.insert(ErrorPair(domain, code))
    }

    /// - Returns: true if the error represents cancellation.
    @objc public var isCancelled: Bool {
        // bizarrely required for `(Swift.Error as NSError).isCancelled` to work, see tests
        return (self as Error).isCancelledError
    }
}

private var cancelledErrorIdentifiers = Set([
    ErrorPair(PMKErrorDomain, PMKOperationCancelled),
    ErrorPair(NSURLErrorDomain, NSURLErrorCancelled),
])

#endif


extension Error {
    public var isCancelledError: Bool {
        if let ce = self as? CancellableError {
            return ce.isCancelled
        } else {
          #if SWIFT_PACKAGE
            return false
          #else
            let ne = self as NSError
            return cancelledErrorIdentifiers.contains(ErrorPair(ne.domain, ne.code))
          #endif
        }
    }
}
