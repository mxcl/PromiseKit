@available(*, deprecated: 4.0)
public enum ErrorPolicy {
    case AllErrorsExceptCancellation
    case AllErrors
}

public enum CatchPolicy {
    case allErrorsExceptCancellation
    case allErrors
}

extension Promise {
    @available(*, deprecated: 3.0, renamed: "ensure(on:that:)")
    public func finally(on: DispatchQueue = .main, _ body: @escaping () -> Void) -> Promise {
        return ensure(on: on, that: body)
    }

    @available(*, deprecated: 5.0, renamed: "ensure(on:that:)")
    public func always(on: DispatchQueue = .main, execute body: @escaping () -> Void) -> Promise {
        return ensure(on: on, that: body)
    }

#if false
    /**
      Disabled; results in the following bad diagnostic:

          func foo() {}
          bar.catch(handler: foo)  // => missing parameter `execute:`

     - Remark: last parameter made invalid so Swift ignores this variant but we can still provide a migration text
     */
    @available(*, deprecated: 5.0, renamed: "catch(on:handler:)")
    public func `catch`(on: DispatchQueue = .main, policy: CatchPolicy = .allErrorsExceptCancellation, execute: Never) {
        fatalError()
    }

    /**
     Disabled; results in the following bad diagnostic:

         Promise().recover {  // => cannot convert value of type `() -> ()` to expected argument `Never`
             foo()
             bar()
         }

     - Remark: last parameter made invalid so Swift ignores this variant but we can still provide a migration text
     */
    @available(*, deprecated: 5.0, renamed: "recover(on:transform:)")
    public func recover(on: DispatchQueue = .main, policy: CatchPolicy = .allErrorsExceptCancellation, execute: Never) {
        fatalError()
    }
#endif

    /// - Remark: last parameter made invalid so Swift ignores this variant but we can still provide a migration text
    @available(*, deprecated: 4.0, renamed: "catch(on:handler:)")
    public func error(on: DispatchQueue = .main, policy: CatchPolicy = .allErrorsExceptCancellation, _ body: Never) {
        fatalError()
    }

    @available(*, deprecated: 4.0, renamed: "catch(on:handler:)")
    public func onError(policy: ErrorPolicy = .AllErrorsExceptCancellation, _ body: @escaping (Error) -> Void) {
        `catch`(handler: body)
    }

    @available(*, deprecated: 3.0, renamed: "catch(on:handler:)")
    public func catch_(policy: ErrorPolicy = .AllErrorsExceptCancellation, body: @escaping (Error) -> Void) {
        `catch`(handler: body)
    }

    @available(*, deprecated: 3.0, renamed: "catch(on:handler:)")
    public func report(policy: ErrorPolicy = .AllErrorsExceptCancellation, body: @escaping (Error) -> Void) {
        `catch`(handler: body)
    }

    @available(*, unavailable, renamed: "pending()")
    public class func `defer`() -> (promise: Promise, fulfill: (T) -> Void, reject: (Error) -> Void) {
        fatalError()
    }

    @available(*, unavailable, renamed: "pending()")
    public class func _defer() -> (promise: Promise, fulfill: (T) -> Void, reject: (Error) -> Void) {
        fatalError()
    }

    @available(*, unavailable, renamed: "pending()")
    public class func pendingPromise() -> (promise: Promise, fulfill: (T) -> Void, reject: (Error) -> Void) {
        fatalError()
    }

    @available(*, deprecated: 4.0, message: "use `then(on: DispatchQoS.background)`")
    public func thenInBackground<U>(body: @escaping (T) -> U) -> Promise<U> {
        return then(on: DispatchQoS.background, execute: body)
    }

    @available(*, deprecated: 4.0, message: "use `then(on: DispatchQoS.background)`")
    public func thenInBackground<U: Thenable>(body: @escaping (T) -> U) -> Promise<U.T> {
        return then(on: DispatchQoS.background, execute: body)
    }
}
