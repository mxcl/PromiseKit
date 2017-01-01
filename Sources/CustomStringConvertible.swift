extension Promise: CustomStringConvertible {
    /// - Returns: A description of the state of this promise.
    public var description: String {
        let isVoid = Wrapped.self == Void.self
        if isFulfilled {
            let value = isVoid ? "" : "\(state)"
            return "Promise(\(value))"
        } else {
            let type = isVoid ? "Void" : "\(Wrapped.self)"
            return "Promise<\(type)>(\(state))"
        }
    }
}

extension AnyPromise {
    /// - Returns: A description of the state of this promise.
    override public var description: String {
        return "AnyPromise(\(state))"
    }
}

extension Result: CustomStringConvertible {
    public var description: String {
        switch self {
        case .fulfilled(let value):
            return "\(value)"
        case .rejected(let error) where error is CustomStringConvertible:
            return "\(error)"
        case .rejected(let error):
            var type: String {
                let typeString = String(describing: type(of: error))
                let parts = typeString.characters.split(separator: " ") // if private class has ugly space separated bits
                if parts.count > 1, let first = parts.first {
                    return String(first.dropFirst()) // whole thing is in paranthesis for some reason
                } else {
                    return typeString
                }
            }
            return "\(type).\(error)"
        }
    }
}

extension UnsealedState: CustomStringConvertible {
    var description: String {
        var rv: String!
        get { seal in
            switch seal {
            case .pending(let handlers):
                rv = ".pending(handlers: \(handlers.count))"
            case .resolved(let result):
                rv = "\(result)"
            }
        }
        return rv
    }
}

extension SealedState: CustomStringConvertible {
    var description: String {
        return "\(result)"
    }
}
