import Dispatch
import Foundation.NSError

/**
 The unhandled error handler.

 If a promise is rejected and no catch handler is called in its chain, the
 provided handler is called. The default handler logs the error.

    PMKUnhandledErrorHandler = { error in
        println("Unhandled error: \(error)")
    }

 @warning *Important* The handler is executed on an undefined queue.

 @warning *Important* Don’t use promises in your handler, or you risk an
 infinite error loop.

 @return The previous unhandled error handler.
*/
public var PMKUnhandledErrorHandler = { (error: NSError) -> Void in
    dispatch_async(dispatch_get_main_queue()) {
        if !error.cancelled {
            NSLog("PromiseKit: Unhandled error: %@", error)
        }
    }
}

private class Consumable: NSObject {
    let parentError: NSError
    var consumed: Bool = false

    deinit {
        if !consumed {
            PMKUnhandledErrorHandler(parentError)
        }
    }
    
    init(parent: NSError) {
        // we take a copy to avoid a retain cycle. A weak ref
        // is no good because then the error is deallocated
        // before we can call PMKUnhandledErrorHandler()
        parentError = parent.copy() as! NSError
    }
}

private var handle: UInt8 = 0

func consume(error: NSError) {
    // The association could be nil if the objc_setAssociatedObject
    // has taken a *really* long time. Or perhaps the user has
    // overused `zalgo`. Thus we ignore it. This is an unlikely edge
    // case and the unhandled-error feature is not mission-critical.

    if let pmke = objc_getAssociatedObject(error, &handle) as? Consumable {
        pmke.consumed = true
    }
}

extension AnyPromise {
    // objc can't see Swift top-level function :(
    //TODO move this and the one in AnyPromise to a compat something
    @objc class func __consume(error: NSError) {
        consume(error)
    }
}

func unconsume(error: NSError) {
    if let pmke = objc_getAssociatedObject(error, &handle) as! Consumable? {
        pmke.consumed = false
    } else {
        // this is how we know when the error is deallocated
        // because we will be deallocated at the same time
        objc_setAssociatedObject(error, &handle, Consumable(parent: error), objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN))
    }
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
