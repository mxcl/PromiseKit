import Dispatch
import Foundation  // NSLog

enum Seal<R> {
    case pending(Handlers<R>)
    case resolved(R)
}

enum Resolution<T> {
    case fulfilled(T)
    case rejected(ErrorProtocol, ErrorConsumptionToken)
}

// would be a protocol, but you can't have typed variables of “generic”
// protocols in Swift 2. That is, I couldn’t do var state: State<R> when
// it was a protocol. There is no work around.
class State<R> {
    func get() -> R? { fatalError("Abstract Base Class") }
    func get(_ body: (Seal<R>) -> Void) { fatalError("Abstract Base Class") }
}

class UnsealedState<R>: State<R> {
    private let barrier = DispatchQueue(label: "org.promisekit.barrier", attributes: .concurrent)
    private var seal: Seal<R>

    /**
     Quick return, but will not provide the handlers array because
     it could be modified while you are using it by another thread.
     If you need the handlers, use the second `get` variant.
    */
    override func get() -> R? {
        var result: R?
        barrier.sync {
            if case .resolved(let resolution) = self.seal {
                result = resolution
            }
        }
        return result
    }

    override func get(_ body: (Seal<R>) -> Void) {
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
            __dispatch_barrier_sync(barrier) {
                switch (self.seal) {
                case .pending:
                    body(self.seal)
                case .resolved:
                    sealed = true  // welcome to race conditions
                }
            }
        }
        if sealed {
            body(seal)
        }
    }

    required init(resolver: inout ((R) -> Void)!) {
        seal = .pending(Handlers<R>())
        super.init()
        resolver = { resolution in
            var handlers: Handlers<R>?
            __dispatch_barrier_sync(self.barrier) {
                if case .pending(let hh) = self.seal {
                    self.seal = .resolved(resolution)
                    handlers = hh
                }
            }
            if let handlers = handlers {
                for handler in handlers {
                    handler(resolution)
                }
            }
        }
    }

    deinit {
        if case .pending = seal {
            NSLog("PromiseKit: Pending Promise deallocated! This is usually a bug")
        }
    }
}

class SealedState<R>: State<R> {
    private let resolution: R
    
    init(resolution: R) {
        self.resolution = resolution
    }
    
    override func get() -> R? {
        return resolution
    }

    override func get(_ body: (Seal<R>) -> Void) {
        body(.resolved(resolution))
    }
}


class Handlers<R>: Sequence {
    var bodies: [(R)->Void] = []

    func append(_ body: (R)->Void) {
        bodies.append(body)
    }

    func makeIterator() -> IndexingIterator<[(R)->Void]> {
        return bodies.makeIterator()
    }

    var count: Int {
        return bodies.count
    }
}


extension Resolution: CustomStringConvertible {
    var description: String {
        switch self {
        case .fulfilled(let value):
            return "Fulfilled with value: \(value)"
        case .rejected(let error):
            return "Rejected with error: \(error)"
        }
    }
}

extension UnsealedState: CustomStringConvertible {
    var description: String {
        var rv: String!
        get { seal in
            switch seal {
            case .pending(let handlers):
                rv = "Pending with \(handlers.count) handlers"
            case .resolved(let resolution):
                rv = "\(resolution)"
            }
        }
        return "UnsealedState: \(rv)"
    }
}

extension SealedState: CustomStringConvertible {
    var description: String {
        return "SealedState: \(resolution)"
    }
}
