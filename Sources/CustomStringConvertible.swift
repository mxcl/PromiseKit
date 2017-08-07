
extension Promise: CustomStringConvertible {
    public var description: String {
        switch result {
        case nil:
            return "Promise(…\(T.self))"
        case .rejected(let error)?:
            return "Promise(\(error))"
        case .fulfilled(let value)?:
            return "Promise(\(value))"
        }
    }
}

extension Promise: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch box.inspect() {
        case .pending(let handlers):
            return "Promise<\(T.self)>.pending(handlers: \(handlers.bodies.count))"
        case .resolved(.rejected(let error)):
            return "Promise<\(T.self)>.rejected(\(type(of: error)).\(error))"
        case .resolved(.fulfilled(let value)):
            return "Promise<\(T.self)>.fulfilled(\(value))"
        }
    }
}
