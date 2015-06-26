import Dispatch
import Foundation.NSError

public enum Error: ErrorType {
    /**
     The ErrorType for a rejected `when`.
     - Parameter 0: The index of the promise that was rejected.
     - Parameter 1: The error from the promise that rejected this `when`.
    */
    case When(Int, ErrorType)
}


/**
 The unhandled error handler.

 If a promise is rejected and no catch handler is called in its chain, the
 provided handler is called. The default handler logs the error.

     PMKUnhandledErrorHandler = { error in
         println("Unhandled error: \(error)")
     }

 - Warning: The handler is executed on an undefined queue.
 - Warning: Don’t use promises in your handler, or you risk an infinite error loop.
 - Returns: The previous unhandled error handler.
*/
public var PMKUnhandledErrorHandler = { (error: ErrorType) -> Void in
    dispatch_async(dispatch_get_main_queue()) {
        if !error.cancelled {
            NSLog("%@", "PromiseKit: Unhandled error: \(error)")
        }
    }
}

func consume(error: ErrorType) {
    // The association could be nil if the objc_setAssociatedObject
    // has taken a *really* long time. Or perhaps the user has
    // overused `zalgo`. Thus we ignore it. This is an unlikely edge
    // case and the unhandled-error feature is not mission-critical.

    // if let pmke = objc_getAssociatedObject(error, &handle) as? Consumable {
    //     pmke.consumed = true
    // }
}

func unconsume(error: ErrorType) {
    // if let pmke = objc_getAssociatedObject(error, &handle) as! Consumable? {
    //     pmke.consumed = false
    // } else {
    //     // this is how we know when the error is deallocated
    //     // because we will be deallocated at the same time
    //     objc_setAssociatedObject(error, &handle, Consumable(parent: error), .OBJC_ASSOCIATION_RETAIN)
    // }
}

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

private var cancelledErrorIdentifiers = Set([
    ErrorPair(PMKErrorDomain, PMKOperationCancelled),
    ErrorPair(NSURLErrorDomain, NSURLErrorCancelled)
])

extension NSError {
    public class func cancelledError() -> NSError {
        let info: [NSObject: AnyObject] = [NSLocalizedDescriptionKey: "The operation was cancelled"]
        return NSError(domain: PMKErrorDomain, code: PMKOperationCancelled, userInfo: info)
    }

    /**
      You may only call this on the main thread.
     */
    public class func registerCancelledErrorDomain(domain: String, code: Int) {
        cancelledErrorIdentifiers.insert(ErrorPair(domain, code))
    }

    /**
     You may only call this on the main thread.
    */
    public var cancelled: Bool {
        return cancelledErrorIdentifiers.contains(ErrorPair(domain, code))
    }
}


extension ErrorType {
    public var cancelled: Bool {
        return (self as NSError).cancelled
    }
}
