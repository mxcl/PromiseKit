import Dispatch
import Foundation.NSError
import Foundation.NSURLError

public enum Error: ErrorType {
    /**
     The ErrorType for a rejected `when`.
     - Parameter 0: The index of the promise that was rejected.
     - Parameter 1: The error from the promise that rejected this `when`.
    */
    case When(Int, ErrorType)

    /**
     The closure with form (T?, ErrorType?) was called with (nil, nil)
     This is invalid as per the calling convention.
    */
    case DoubleOhSux0r
}


//////////////////////////////////////////////////////////// Cancellation
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
    @objc class func cancelledError() -> NSError {
        let info: [NSObject: AnyObject] = [NSLocalizedDescriptionKey: "The operation was cancelled"]
        return NSError(domain: PMKErrorDomain, code: PMKOperationCancelled, userInfo: info)
    }

    /**
      - Warning: You may only call this method on the main thread.
     */
    @objc public class func registerCancelledErrorDomain(domain: String, code: Int) {
        cancelledErrorIdentifiers.insert(ErrorPair(domain, code))
    }
}

public protocol CancellableErrorType: ErrorType {
    var cancelled: Bool { get }
}

extension NSError: CancellableErrorType {
    /**
     - Warning: You may only call this method on the main thread.
    */
    @objc public var cancelled: Bool {
        return cancelledErrorIdentifiers.contains(ErrorPair(domain, code))
    }
}


////////////////////////////////////////// Predefined Cancellation Errors
private var cancelledErrorIdentifiers = Set([
    ErrorPair(PMKErrorDomain, PMKOperationCancelled),
    ErrorPair(NSURLErrorDomain, NSURLErrorCancelled)
])

extension NSURLError: CancellableErrorType {
    public var cancelled: Bool {
        return self == .Cancelled
    }
}


//////////////////////////////////////////////////////// Unhandled Errors
/**
 The unhandled error handler.

 If a promise is rejected and no catch handler is called in its chain,
 the provided handler is called. The default handler logs the error.

     PMKUnhandledErrorHandler = { error in
         mylogf("Unhandled error: \(error)")
     }

 - Warning: *Important* The handler is executed on an undefined queue.
 - Warning: *Important* Don’t use promises in your handler, or you risk an infinite error loop.
 - Returns: The previous unhandled error handler.
*/
public var PMKUnhandledErrorHandler = { (error: ErrorType) -> Void in
    dispatch_async(dispatch_get_main_queue()) {
        let cancelled = (error as? CancellableErrorType)?.cancelled ?? false
                                                       // ^-------^ must be called on main queue
        if !cancelled {
            NSLog("PromiseKit: Unhandled Error: %@", "\(error)")
        }
    }
}

class ErrorConsumptionToken {
    var consumed = false
    let error: ErrorType!

    init(_ error: ErrorType) {
        self.error = error
    }

    init(_ error: NSError) {
        self.error = error.copy() as! NSError
    }

    deinit {
        if !consumed {
            PMKUnhandledErrorHandler(error)
        }
    }
}

private var handle: UInt8 = 0

extension NSError {
    @objc func pmk_consume() {
        // The association could be nil if the objc_setAssociatedObject
        // has taken a *really* long time. Or perhaps the user has
        // overused `zalgo`. Thus we ignore it. This is an unlikely edge
        // case and the unhandled-error feature is not mission-critical.

        if let token = objc_getAssociatedObject(self, &handle) as? ErrorConsumptionToken {
            token.consumed = true
        }
    }
}

func unconsume(error error: NSError, var reusingToken token: ErrorConsumptionToken? = nil) {
    if token != nil {
        objc_setAssociatedObject(error, &handle, token, .OBJC_ASSOCIATION_RETAIN)
    } else {
        token = objc_getAssociatedObject(error, &handle) as? ErrorConsumptionToken
        if token == nil {
            token = ErrorConsumptionToken(error)
            objc_setAssociatedObject(error, &handle, token, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    token!.consumed = false
}
