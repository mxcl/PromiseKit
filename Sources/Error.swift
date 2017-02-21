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

    /// `Promise.flatMap(_:)` failed to transform `$0` to `$1`
    case flatMap(Any, Any.Type)

    /// The operation was cancelled
    case cancelled
}

extension PMKError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .flatMap(let obj, let type):
            return "Could not `flatMap<\(type)>`: \(obj)"
        case .invalidCallingConvention:
            return "A closure was called with an invalid calling convention, probably (nil, nil)"
        case .returnedSelf:
            return "A promise handler returned itself"
        case .badInput:
            return "Bad input was provided to a PromiseKit function"
        case .cancelled:
            return "The operation was cancelled"
        }
    }
}

@objc(PMKCatchPolicy)
public enum CatchPolicy: Int {
    case allErrors
    case allErrorsExceptCancellation
}

extension NSError {
    @objc(pmk_cancelledError)
    public static var cancelledError: NSError {
        return PMKError.cancelled as NSError
    }
}

extension Error {
    public var isCancelled: Bool {
        do {
            throw self
        } catch PMKError.cancelled {
            return true
        } catch {
            return false
        }
    }
}
