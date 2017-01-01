/**
 Makes the signature for chainable operations simpler, also
 enables us to avoid entire classes of @unavailable annotations,
 see PromiseKit 4 for examples of what has been cleaned up.
 
 Conversion of everything to a promise is relatively cheap, since
 we have an optimized—lock free—path for `SealedState`.
 
 However ideally we’d avoid that if possible FIXME
*/
public protocol Chainable {
    associatedtype Wrapped

    // convert this type into a `Promise`
    var promise: Promise<Wrapped> { get }
}

internal extension Chainable {
    func pipe(to pipe: Pipe<Wrapped>) {
        promise.pipe(to: pipe)
    }
    var state: State<Wrapped> {
        return promise.state
    }
}

extension Any: Chainable {
    public var promise: Promise { return Promise(self) }
}

extension Promise: Chainable {
    public var promise: Promise { return self }
}

extension AnyPromise: Chainable {
    public var promise: Promise { return asPromise() }
}

public protocol Promisey {}
extension Promise: Promisey {}
extension AnyPromise: Promisey {}

extension Optional where Wrapped: Promisey, Wrapped: Chainable {
    public var promise: Wrapped {
        switch self {
        case .some(let Wrapped):
            return Wrapped
        case .none:
            fatalError("Cannot figure this out")  //FIXME!
        }
    }
}
