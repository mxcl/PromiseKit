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

    /** `when()`, `race()` etc. were called with invalid parameters, eg. an empty array. */
    case badInput

    /// The operation was cancelled
    case cancelled

    /// `nil` was returned from `flatMap`
    @available(*, deprecated: 6.1, message: "See: compactMap")
    case flatMap(Any, Any.Type)

    case compactMap(Any, Any.Type)
}

extension PMKError: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .flatMap(let obj, let type):
            return "Could not `flatMap<\(type)>`: \(obj)"
        case .compactMap(let obj, let type):
            return "Could not `compactMap<\(type)>`: \(obj)"
        case .invalidCallingConvention:
            return "A closure was called with an invalid calling convention, probably (nil, nil)"
        case .returnedSelf:
            return "A promise handler returned itself"
        case .badInput:
            return "Bad input was provided to a PromiseKit function"
        case .cancelled:
            return "The asynchronous sequence was cancelled"
        }
    }
}

extension PMKError: LocalizedError {
    public var errorDescription: String? {
        return debugDescription
    }
}


//////////////////////////////////////////////////////////// Cancellation

public protocol CancellableError: Error {
    var isCancelled: Bool { get }
}

extension Error {
    public var isCancelled: Bool {
        do {
            throw self
        } catch PMKError.cancelled {
            return true
        } catch let error as CancellableError {
            return error.isCancelled
        } catch URLError.cancelled {
            return true
        } catch CocoaError.userCancelled {
            return true
        } catch {
            return false
        }
    }
}

public enum CatchPolicy {
    case allErrors
    case allErrorsExceptCancellation
}
