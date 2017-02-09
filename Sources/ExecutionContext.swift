import Foundation

public protocol ExecutionContext {
    // `pmk` prefix otherwise `DispatchQueue.async` becomes ambiguous
    // in files that `import PromiseKit`… :{
    func pmkAsync(execute: @escaping () -> Void)
}

extension DispatchQueue: ExecutionContext {
    public func pmkAsync(execute body: @escaping () -> Void) {
        async(execute: body)
    }
}

extension DispatchQoS: ExecutionContext {
    public func pmkAsync(execute body: @escaping () -> Void) {
        DispatchQueue.global().async(group: nil, qos: self, flags: [], execute: body)
    }
}

extension QualityOfService: ExecutionContext {
    public var dispatchQoS: DispatchQoS {
        switch self {
        case .background:
            return .background
        case .default:
            return .default
        case .userInitiated:
            return .userInitiated
        case .userInteractive:
            return .userInteractive
        case .utility:
            return .utility
        }
    }

    public func pmkAsync(execute body: @escaping () -> Void) {
        dispatchQoS.pmkAsync(execute: body)
    }
}

private enum State {
    case pending([() -> Void])
    case expired
}

private let barrier = DispatchQueue(label: "org.promisekit.barrier.exectx", attributes: .concurrent)
private var activeContext: NextMainRunloopContext.Context?

/**
 See the Promises/A+ specification for any details not clear.
 
 An optimized model that ensures all handlers wait at least one main-runloop-iteration before
 being executed.
 
 Note, if you are not on the main-thread this means your handler *may* execute before the current
 execution context of your thread ends. This technically violates Promises/A+ but we can’t see a
 good way around it.
 
 This is the defualt `ExecutionContext` for all PromiseKit handlers (eg. `then`).
*/
public class NextMainRunloopContext: ExecutionContext {

    private let context: Context

    fileprivate class Context {
        enum State {
            case pending([() -> Void])
            case expired
        }
        var state = State.pending([])

        init() {
            DispatchQueue.main.async {
                var handlers: Array<() -> Void>!
                barrier.sync(flags: .barrier) {
                    assert(activeContext === self)

                    activeContext = nil

                    switch self.state {
                    case .pending(let hh):
                        handlers = hh
                    case .expired:
                        fatalError()
                    }
                    self.state = .expired

                }
                handlers.forEach{ $0() }
            }
        }
    }

    init() {
        var ctx: Context!
        barrier.sync(flags: .barrier) {
            ctx = activeContext ?? Context()
            activeContext = ctx
        }
        context = ctx
    }

    public func pmkAsync(execute body: @escaping () -> Void) {  //FIXME needs locks
        var expired: Bool!
        barrier.sync {
            if case .expired = self.context.state { expired = true } else { expired = false }
        }
        if expired {
            body()
        } else {
            barrier.sync(flags: .barrier) {
                switch self.context.state {
                case .pending(let handlers):
                    self.context.state = .pending(handlers + [body])
                case .expired:
                    expired = true
                }
            }
            if expired {
                body()
            }
        }
    }
}

public class Zalgo: ExecutionContext {
    @inline(__always)
    public func pmkAsync(execute body: @escaping () -> Void) {
        body()
    }
}

// global variable to ease backwards compatibility
public let zalgo = Zalgo()
