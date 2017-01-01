import class Dispatch.DispatchQueue
import func Foundation.NSLog

enum Seal<T> {
    case pending(Handlers<T>)
    case resolved(Result<T>)
}

class State<T> {

    // would be a protocol, but you can't have typed variables of “generic”
    // protocols in Swift 2. That is, I couldn’t do var state: State<R> when
    // it was a protocol. There is no work around. Update: nor Swift 3

    func get() -> Result<T>? { fatalError("Abstract Base Class") }
    func get(body: @escaping (Seal<T>) -> Void) { fatalError("Abstract Base Class") }

    final func pipe(afterExecutionContext: Bool = false, _ body: @escaping (Result<T>) -> Void) {
        get { seal in
            switch seal {
            case .pending(let handlers):
                handlers.append(body)
            case .resolved(let result):
                body(result)
            }
        }
    }
}

class UnsealedState<T>: State<T> {
    private let barrier = DispatchQueue(label: "org.promisekit.barrier", attributes: .concurrent)
    private var seal: Seal<T>

    /**
     Quick return, but will not provide the handlers array because
     it could be modified while you are using it by another thread.
     If you need the handlers, use the second `get` variant.
     */
    override func get() -> Result<T>? {
        var rv: Result<T>?
        barrier.sync {
            if case .resolved(let result) = self.seal {
                rv = result
            }
        }
        return rv
    }

    override func get(body: @escaping (Seal<T>) -> Void) {
        var sealed = false
        barrier.sync {
            switch self.seal {
            case .resolved:
                sealed = true
            case .pending:
                sealed = false
            }
        }
        if !sealed {
            barrier.sync(flags: .barrier) {
                switch (self.seal) {
                case .pending:
                    body(self.seal)
                case .resolved:
                    sealed = true  // welcome to race conditions
                }
            }
        }
        if sealed {
            body(seal)  // as much as possible we do things OUTSIDE the barrier_sync
        }
    }

    required init(resolver: inout ((Result<T>) -> Void)!) {
        seal = .pending(Handlers<T>())
        super.init()
        resolver = { result in
            var handlers: Handlers<T>?
            self.barrier.sync(flags: .barrier) {
                if case .pending(let hh) = self.seal {
                    self.seal = .resolved(result)
                    handlers = hh
                }
            }
            if let handlers = handlers {
                for handler in handlers { // due to XCTestExpectations not running their own pool
                    handler(result)
                }
            }
        }
    }
#if !PMKDisableWarnings
    deinit {
        if case .pending = seal {
            NSLog("PromiseKit: warning: pending `Promise` deallocated! This is *usually* a bug!")
        }
    }
#endif
}

class SealedState<T>: State<T> {
    let result: Result<T>
    
    init(result: Result<T>) {
        self.result = result
    }
    
    override func get() -> Result<T>? {
        return result
    }

    override func get(body: @escaping (Seal<T>) -> Void) {
        body(.resolved(result))
    }
}


class Handlers<T>: Sequence {
    private var bodies: [(Result<T>) -> Void] = []

    func append(_ body: @escaping (Result<T>) -> Void) {
        bodies.append(body)
    }

    func makeIterator() -> IndexingIterator<[(Result<T>) -> Void]> {
        return bodies.makeIterator()
    }

    var count: Int {
        return bodies.count
    }
}
