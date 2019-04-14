import Dispatch

// These are protocols that define DispatchQueue-based wrappers for functions that are found on multiple
// entities. By putting the wrappers in a separate mixin protocol, they can be added to the objects
// without duplication.
//
// Ideally, we would just add the mixin to protocols such as Thenable. However, Swift (as of v5)
// does not allow protocol extension that add conformance to other protocols. The underlying issue is the risk
// of overlapping conformances. See https://goo.gl/rViwWS. The workaround is to declare conformance on each
// underlying object separately.
//
// Associated types within protocols may not be generic, so there are many functions that can't be genericized
// in this way. For example, anything of the form `func foo<U>(_ body: () -> U) -> Promise<U>` is unrepresentable.
//
// These protocols have to be public to make their contents accessible to users, but the protocols themselves
// should never appear in Xcode or in the documentation.

public protocol _PMKSharedWrappers {
    
    associatedtype T
    associatedtype BaseOfT
    associatedtype BaseOfVoid
    associatedtype VoidReturn

    func done(on: Dispatcher, _ body: @escaping(T) throws -> Void) -> BaseOfVoid
    func get(on: Dispatcher, _ body: @escaping(T) throws -> Void) -> BaseOfT
    func tap(on: Dispatcher, _ body: @escaping(Result<T, Error>) -> Void) -> BaseOfT

    func recover<U: Thenable>(on: Dispatcher, policy: CatchPolicy, _ body: @escaping(Error) throws -> U) -> BaseOfT where U.T == T
    func recover<U: Thenable, E: Swift.Error>(only: E, on: Dispatcher, _ body: @escaping(E) throws -> U) -> BaseOfT where U.T == T, E: Equatable
    func recover<U: Thenable, E: Swift.Error>(only: E.Type, on: Dispatcher, policy: CatchPolicy, _ body: @escaping(E) throws -> U) -> BaseOfT where U.T == T

    func ensure(on: Dispatcher, _ body: @escaping () -> Void) -> BaseOfT
    func ensureThen(on: Dispatcher, _ body: @escaping () -> VoidReturn) -> BaseOfT
    
    func dispatch(on: Dispatcher) -> BaseOfT
}

extension Promise: _PMKSharedWrappers {
    public typealias T = T
    public typealias BaseOfT = Promise<T>
}

extension CancellablePromise: _PMKSharedWrappers {
    public typealias T = T
    public typealias BaseOfT = CancellablePromise<T>
}

public protocol _PMKSharedVoidWrappers {
    
    associatedtype BaseOfT
    
    func recover(on: Dispatcher, policy: CatchPolicy, _ body: @escaping(Error) throws -> Void) -> BaseOfT
    func recover<E: Swift.Error>(only: E, on: Dispatcher, _ body: @escaping(E) throws -> Void) -> BaseOfT where E: Equatable
    func recover<E: Swift.Error>(only: E.Type, on: Dispatcher, policy: CatchPolicy, _ body: @escaping(E) throws -> Void) -> BaseOfT
}

extension Promise: _PMKSharedVoidWrappers where T == Void {}
extension CancellablePromise: _PMKSharedVoidWrappers where C.T == Void {}

public protocol _PMKCatchWrappers {
    
    associatedtype Finalizer
    associatedtype CascadingFinalizer
    
    func `catch`(on: Dispatcher, policy: CatchPolicy, _ body: @escaping(Error) -> Void) -> Finalizer
    func `catch`<E: Swift.Error>(only: E, on: Dispatcher, _ body: @escaping(E) -> Void) -> CascadingFinalizer where E: Equatable
    func `catch`<E: Swift.Error>(only: E.Type, on: Dispatcher, policy: CatchPolicy, _ body: @escaping(E) -> Void) -> CascadingFinalizer
}

extension Promise: _PMKCatchWrappers {}
extension PMKCascadingFinalizer: _PMKCatchWrappers {}
extension CancellablePromise: _PMKCatchWrappers {}
extension CancellableCascadingFinalizer: _PMKCatchWrappers {}

public protocol _PMKFinallyWrappers {
    
    associatedtype FinallyReturn
    
    func finally(on: Dispatcher, _ body: @escaping () -> Void) -> FinallyReturn
}

extension PMKFinalizer: _PMKFinallyWrappers {}
extension CancellableFinalizer: _PMKFinallyWrappers {}
