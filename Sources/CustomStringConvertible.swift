
extension Promise: CustomStringConvertible {
    /// - Returns: A description of the state of this promise.
    public var description: String {
        switch result {
        case nil:
            return "Promise(…\(T.self))"
        case .failure(let error)?:
            return "Promise(\(error))"
        case .success(let value)?:
            return "Promise(\(value))"
        }
    }
}

extension Promise: CustomDebugStringConvertible {
    /// - Returns: A debug-friendly description of the state of this promise.
    public var debugDescription: String {
        switch box.inspect() {
        case .pending(let handlers):
            return "Promise<\(T.self)>.pending(handlers: \(handlers.bodies.count))"
        case .resolved(.failure(let error)):
            return "Promise<\(T.self)>.failure(\(type(of: error)).\(error))"
        case .resolved(.success(let value)):
            return "Promise<\(T.self)>.success(\(value))"
        }
    }
}
