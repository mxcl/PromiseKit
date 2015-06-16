import Foundation.NSError

enum Resolution<T> {
    case Fulfilled(T)
    case Rejected(NSError)
}

enum Seal<T> {
    case Pending(Handlers<T>)
    case Resolved(Resolution<T>)
}

// would be a protocol, but you can't have typed variables of “generic”
// protocols in Swift 2. That is, I couldn’t do var state: State<T> when
// it was a protocol. There is no work around.
class State<T> {
    func get() -> Resolution<T>? { fatalError("Abstract Base Class") }
    func get(body: (Seal<T>) -> Void) { fatalError("Abstract Base Class") }
}

class UnsealedState<T>: State<T> {
    private let barrier = dispatch_queue_create("org.promisekit.barrier", DISPATCH_QUEUE_CONCURRENT)
    private var seal: Seal<T>

    /**
     Quick return, but will not provide the handlers array because
     it could be modified while you are using it by another thread.
     If you need the handlers, use the second `get` variant.
    */
    override func get() -> Resolution<T>? {
        var result: Resolution<T>?
        dispatch_sync(barrier) {
            if case .Resolved(let resolution) = self.seal {
                result = resolution
            }
        }
        return result
    }

    override func get(body: (Seal<T>) -> Void) {
        var sealed = false
        dispatch_sync(barrier) {
            switch self.seal {
            case .Resolved:
                sealed = true
            case .Pending:
                sealed = false
            }
        }
        if !sealed {
            dispatch_barrier_sync(barrier) {
                switch (self.seal) {
                case .Pending:
                    body(self.seal)
                case .Resolved:
                    sealed = true  // welcome to race conditions
                }
            }
        }
        if sealed {
            body(seal)
        }
    }

    init(inout resolver: ((Resolution<T>) -> Void)!) {
        seal = .Pending(Handlers<T>())
        super.init()
        resolver = { resolution in
            var handlers: Handlers<T>?
            dispatch_barrier_sync(self.barrier) {
                if case .Pending(let hh) = self.seal {
                    self.seal = .Resolved(resolution)
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
}

class SealedState<T>: State<T> {
    private let resolution: Resolution<T>
    
    init(resolution: Resolution<T>) {
        self.resolution = resolution
    }
    
    override func get() -> Resolution<T>? {
        return resolution
    }

    override func get(body: (Seal<T>) -> Void) {
        body(.Resolved(resolution))
    }
}


class Handlers<T>: SequenceType {
    var bodies: [(Resolution<T>)->()] = []

    func append(body: (Resolution<T>)->()) {
        bodies.append(body)
    }

    func generate() -> IndexingGenerator<[(Resolution<T>)->()]> {
        return bodies.generate()
    }

    var count: Int {
        return bodies.count
    }
}


extension Resolution: CustomStringConvertible {
    var description: String {
        switch self {
        case .Fulfilled(let value):
            return "Fulfilled with value: \(value)"
        case .Rejected(let error):
            return "Rejected with error: \(error)"
        }
    }
}

extension UnsealedState: CustomStringConvertible {
    var description: String {
        var rv: String?
        get { seal in
            switch seal {
            case .Pending(let handlers):
                rv = "Pending with \(handlers.count) handlers"
            case .Resolved(let resolution):
                rv = "\(resolution)"
            }
        }
        return "UnsealedState: \(rv!)"
    }
}

extension SealedState: CustomStringConvertible {
    var description: String {
        return "SealedState: \(resolution)"
    }
}
