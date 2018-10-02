import Foundation

public enum PMKError: Error {
    /**
     The completionHandler with form `(T?, Error?)` was called with `(nil, nil)`.
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
    @available(*, deprecated, message: "See: `compactMap`")
    case flatMap(Any, Any.Type)

    /// `nil` was returned from `compactMap`
    case compactMap(Any, Any.Type)

    /**
     The lastValue or firstValue of a sequence was requested but the sequence was empty.

     Also used if all values of this collection failed the test passed to `firstValue(where:)`.
     */
    case emptySequence
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
        case .emptySequence:
            return "The first or last element was requested for an empty sequence"
        }
    }
}

extension PMKError: LocalizedError {
    public var errorDescription: String? {
        return debugDescription
    }
}


//////////////////////////////////////////////////////////// Cancellation

/// An error that may represent the cancelled condition
public protocol CancellableError: Error {
    /// returns true if this Error represents a cancelled condition
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
        #if os(macOS) || os(iOS) || os(tvOS)
            let pair = { ($0.domain, $0.code) }(error as NSError)
            return ("SKErrorDomain", 2) == pair
        #else
            return false
        #endif
        }
    }
}

/// Used by `catch` and `recover`
public enum CatchPolicy {
    /// Indicates that `catch` or `recover` handle all error types including cancellable-errors.
    case allErrors

    /// Indicates that `catch` or `recover` handle all error except cancellable-errors.
    case allErrorsExceptCancellation
}
