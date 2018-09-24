/// An object for resolving promises
public class Resolver<T> {
    let box: Box<Result<T>>

    init(_ box: Box<Result<T>>) {
        self.box = box
    }

    deinit {
        if case .pending = box.inspect() {
            print("PromiseKit: warning: pending promise deallocated")
        }
    }
}

public extension Resolver {
    /// Fulfills the promise with the provided value
    func fulfill(_ value: T) {
        box.seal(.fulfilled(value))
    }

    /// Rejects the promise with the provided error
    func reject(_ error: Error) {
        box.seal(.rejected(error))
    }

    /// Resolves the promise with the provided result
    public func resolve(_ result: Result<T>) {
        box.seal(result)
    }

    /// Resolves the promise with the provided value or error
    public func resolve(_ obj: T?, _ error: Error?) {
        if let error = error {
            reject(error)
        } else if let obj = obj {
            fulfill(obj)
        } else {
            reject(PMKError.invalidCallingConvention)
        }
    }

    /// Fulfills the promise with the provided value unless the provided error is non-nil
    public func resolve(_ obj: T, _ error: Error?) {
        if let error = error {
            reject(error)
        } else {
            fulfill(obj)
        }
    }

    /// Resolves the promise, provided for non-conventional value-error ordered completion handlers.
    public func resolve(_ error: Error?, _ obj: T?) {
        resolve(obj, error)
    }
}

#if swift(>=3.1)
extension Resolver where T == Void {
    /// Fulfills the promise unless error is non-nil
    public func resolve(_ error: Error?) {
        if let error = error {
            reject(error)
        } else {
            fulfill(())
        }
    }
}
#endif

public enum Result<T> {
    case fulfilled(T)
    case rejected(Error)
}

public extension PromiseKit.Result {
    var isFulfilled: Bool {
        switch self {
        case .fulfilled:
            return true
        case .rejected:
            return false
        }
    }
}
