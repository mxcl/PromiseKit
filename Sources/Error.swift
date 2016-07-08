import Foundation

public enum Error: ErrorProtocol {
    /**
     The ErrorType for a rejected `when`.
     - Parameter 0: The index of the promise that was rejected.
     - Parameter 1: The error from the promise that rejected this `when`.
    */
    case when(Int, ErrorProtocol)

    /**
     The ErrorType for a rejected `join`.
     - Parameter 0: The promises passed to this `join` that did not *all* fulfill.
     - Note: The array is untyped because Swift generics are fussy with enums.
    */
    case join([AnyObject])

    /**
     The closure with form (T?, ErrorType?) was called with (nil, nil)
     This is invalid as per the calling convention.
    */
    case invalidCompletionHandlerCallingConvention

    /**
     A handler returned its own promise. 99% of the time, this is likely a 
     programming error. It is also invalid per Promises/A+.
    */
    case returnedSelf
}

public enum URLError: ErrorProtocol {
    /**
     The URLRequest succeeded but a valid UIImage could not be decoded from
     the data that was received.
    */
    case invalidImageData(URLRequest, Data)

    /**
     An NSError was received from an underlying Cocoa function.
    */
    case underlyingCocoaError(URLRequest, Data?, URLResponse?, NSError)

    /**
     The HTTP request returned a non-200 status code.
    */
    case badResponse(URLRequest, Data?, URLResponse?)

    /**
     The data could not be decoded using the encoding specified by the HTTP
     response headers.
    */
    case stringEncoding(URLRequest, Data, URLResponse)

    /**
     Usually the `NSURLResponse` is actually an `NSHTTPURLResponse`, if so you
     can access it using this property. Since it is returned as an unwrapped
     optional: be sure.
    */
    public var NSHTTPURLResponse: Foundation.HTTPURLResponse! {
        switch self {
        case .invalidImageData:
            return nil
        case .underlyingCocoaError(_, _, let rsp, _):
            return rsp as! Foundation.HTTPURLResponse
        case .badResponse(_, _, let rsp):
            return rsp as! Foundation.HTTPURLResponse
        case .stringEncoding(_, _, let rsp):
            return rsp as! Foundation.HTTPURLResponse
        }
    }
}

public enum JSONError: ErrorProtocol {
    case unexpectedRootNode(AnyObject)
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
    @objc public class func cancelledError() -> NSError {
        let info: [NSObject: AnyObject] = [NSLocalizedDescriptionKey: "The operation was cancelled"]
        return NSError(domain: PMKErrorDomain, code: PMKOperationCancelled, userInfo: info)
    }

    /**
      - Warning: You must call this method before any promises in your application are rejected. Failure to ensure this may lead to concurrency crashes.
      - Warning: You must call this method on the main thread. Failure to do this may lead to concurrency crashes.
     */
    @objc public class func registerCancelledErrorDomain(_ domain: String, code: Int) {
        cancelledErrorIdentifiers.insert(ErrorPair(domain, code))
    }

    @objc public var isCancelled: Bool {
        return (self as ErrorProtocol).isCancelledError
    }
}

public protocol CancellableError: ErrorProtocol {
    var isCancelled: Bool { get }
}

extension ErrorProtocol {
    public var isCancelledError: Bool {
        if let ce = self as? CancellableError {
            return ce.isCancelled
        } else {
            let ne = self as NSError
            return cancelledErrorIdentifiers.contains(ErrorPair(ne.domain, ne.code))
        }
    }
}


////////////////////////////////////////// Predefined Cancellation Errors
private var cancelledErrorIdentifiers = Set([
    ErrorPair(PMKErrorDomain, PMKOperationCancelled),
    ErrorPair(NSURLErrorDomain, NSURLErrorCancelled),
])


//////////////////////////////////////////////////////// Unhandled Errors
class ErrorConsumptionToken {
    var consumed = false
    let error: ErrorProtocol

    init(_ error: ErrorProtocol) {
        self.error = error
    }

    deinit {
        if !consumed {
            PMKUnhandledErrorHandler(error as NSError)
        }
    }
}
