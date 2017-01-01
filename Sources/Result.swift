/**
 The underlying resolved state of a promise.
 - Remark: Same as `Resolution<T>` but without the associated `ErrorConsumptionToken`.
 */
public enum Result<T> {
    /// Fulfillment
    case fulfilled(T)
    /// Rejection
    case rejected(Error)

    public var value: Any {
        switch self {
        case .fulfilled(let value):
            return value
        case .rejected(let error):
            return error
        }
    }

    /**
     - Returns: `true` if the result is `fulfilled` or `false` if it is `rejected`.
     */
    public var boolValue: Bool {
        switch self {
        case .fulfilled:
            return true
        case .rejected:
            return false
        }
    }

    func unwrap() throws -> T {
        switch self {
        case .fulfilled(let value):
            return value
        case .rejected(let error):
            throw error
        }
    }
}
