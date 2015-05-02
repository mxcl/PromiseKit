import Foundation.NSError

extension Promise {
    /**
     @return The error with which this promise was rejected; nil if this promise is not rejected.
    */
    public var error: NSError? {
        switch state.get() {
        case .None:
            return nil
        case .Some(.Fulfilled):
            return nil
        case .Some(.Rejected(let error)):
            return error
        }
    }

    /**
     @return `YES` if the promise has not yet resolved.
    */
    public var pending: Bool {
        return state.get() == nil
    }

    /**
     @return `YES` if the promise has resolved.
    */
    public var resolved: Bool {
        return !pending
    }

    /**
     @return `YES` if the promise was fulfilled.
    */
    public var fulfilled: Bool {
        return value != nil
    }

    /**
     @return `YES` if the promise was rejected.
    */
    public var rejected: Bool {
        return error != nil
    }
}
