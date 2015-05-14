import Foundation.NSError

enum Resolution {
    case Fulfilled(Any)    //TODO make type T when Swift can handle it
    case Rejected(NSError)
}

enum Seal {
    case Pending(Handlers)
    case Resolved(Resolution)
}

protocol State {
    func get() -> Resolution?
    func get(body: (Seal) -> Void)
}

class UnsealedState: State {
    private let barrier = dispatch_queue_create("org.promisekit.barrier", DISPATCH_QUEUE_CONCURRENT)
    private var seal: Seal

    /**
     Quick return, but will not provide the handlers array
     because it could be modified while you are using it by
     another thread. If you need the handlers, use the second
     `get` variant.
    */
    func get() -> Resolution? {
        var result: Resolution?
        dispatch_sync(barrier) {
            switch self.seal {
            case .Resolved(let resolution):
                result = resolution
            case .Pending:
                break
            }
        }
        return result
    }

    func get(body: (Seal) -> Void) {
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

    init(inout resolver: ((Resolution) -> Void)!) {
        seal = .Pending(Handlers())
        resolver = { resolution in
            var handlers: Handlers?
            dispatch_barrier_sync(self.barrier) {
                switch self.seal {
                case .Pending(let hh):
                    self.seal = .Resolved(resolution)
                    handlers = hh
                case .Resolved:
                    break
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

class SealedState: State {
    private let resolution: Resolution
    
    init(resolution: Resolution) {
        self.resolution = resolution
    }
    
    func get() -> Resolution? {
        return resolution
    }
    func get(body: (Seal) -> Void) {
        body(.Resolved(resolution))
    }
}


class Handlers: SequenceType {
    var bodies: [(Resolution)->()] = []

    func append(body: (Resolution)->()) {
        bodies.append(body)
    }

    func generate() -> IndexingGenerator<[(Resolution)->()]> {
        return bodies.generate()
    }

    var count: Int {
        return bodies.count
    }
}


extension Resolution: DebugPrintable {
    var debugDescription: String {
        switch self {
        case Fulfilled(let value):
            return "Fulfilled with value: \(value)"
        case Rejected(let error):
            return "Rejected with error: \(error)"
        }
    }
}

extension UnsealedState: DebugPrintable {
    var debugDescription: String {
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

extension SealedState: DebugPrintable {
    var debugDescription: String {
        return "SealedState: \(resolution)"
    }
}
