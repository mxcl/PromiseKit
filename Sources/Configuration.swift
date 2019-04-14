import Dispatch

// PromiseKit’s configurable parameters.

public struct NoValue: Dispatcher {
    public init() {}
    public func dispatch(_ body: @escaping () -> Void) {
        fatalError("NoValue dispatcher should never actually be used as a dispatcher")
    }
}

public struct PMKConfiguration {
    
    public var requireChainConfirmation = true
    
    /// Backward compatibility: the default Dispatcher to which handlers dispatch, represented as DispatchQueues.
    @available(*, deprecated, message: "Use conf.setDefaultDispatchers(body:tail:) to set default dispatchers in PromiseKit 7+")
    public var Q: (map: DispatchQueue?, return: DispatchQueue?) {
        get {
            let convertedMap = _D.body is CurrentThreadDispatcher ? nil : _D.body as? DispatchQueue
            let convertedReturn = _D.tail is CurrentThreadDispatcher ? nil : _D.tail as? DispatchQueue
            return (map: convertedMap, return: convertedReturn)
        }
        set {
            verifyDUnread()
            _D = (body: newValue.map ?? CurrentThreadDispatcher(), tail: newValue.return ?? CurrentThreadDispatcher())
        }
    }

    /// The default Dispatchers to which promise handlers dispatch
    private static let defaultBodyDispatcher = DispatchQueue.main
    private static let defaultTailDispatcher = DispatchQueue.main
    
    internal var _D: (body: Dispatcher, tail: Dispatcher) = (body: DispatchQueue.main, tail: DispatchQueue.main)
    internal var D: (body: Dispatcher, tail: Dispatcher) {
        mutating get { dRead = true; return _D }
        set { _D = newValue }
    }
    
    private var dRead = false
    internal var testMode = false

    /// The default catch-policy for all `catch` and `resolve`
    public var catchPolicy = CatchPolicy.allErrorsExceptCancellation
    
    /// The closure used to log PromiseKit events.
    /// Not thread safe; change before processing any promises.
    /// - Note: The default handler calls `print()`
    public var logHandler: (LogEvent) -> () = { event in
        print(event.asString())
    }
    
    private func verifyDUnread() {
        if dRead && !testMode {
            conf.logHandler(.defaultDispatchersReset)
        }
    }
    
    mutating public func setDefaultDispatchers(body: Dispatcher = NoValue(), tail: Dispatcher = NoValue()) {
        verifyDUnread()
        if !(body is NoValue) { _D.body = body }
        if !(tail is NoValue) { _D.tail = tail }
    }
    
    fileprivate func determineDispatcher(_ dispatcher: DispatchQueue?, default: Dispatcher) -> Dispatcher? {
        switch dispatcher {
            case nil:
                return CurrentThreadDispatcher()
            case DispatchQueue.unspecified:
                return nil // Do nothing
            case DispatchQueue.default:
                return `default`
            case DispatchQueue.chain:
                fatalError("PromiseKit: .chain is not meaningful in the context of setDefaultDispatchers")
            default:
                return dispatcher!
        }
    }

    mutating public func setDefaultDispatchers(body: DispatchQueue? = .unspecified, tail: DispatchQueue? = .unspecified) {
        verifyDUnread()
        if let newBody = determineDispatcher(body, default: PMKConfiguration.defaultBodyDispatcher) {
            _D.body = newBody
        }
        if let newTail = determineDispatcher(tail, default: PMKConfiguration.defaultTailDispatcher) {
            _D.tail = newTail
        }
   }
}

/// Modify this as soon as possible in your application’s lifetime
public var conf = PMKConfiguration()
