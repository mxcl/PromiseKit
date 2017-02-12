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
 
 This is the default `ExecutionContext` for all PromiseKit handlers (eg. `then`).
*/
public class NextMainRunloopContext: ExecutionContext {

    private let context: Context

    fileprivate class Context {
        var expired = false

        init() {
            DispatchQueue.main.async {
                barrier.sync(flags: .barrier) {
                    self.expired = true
                    activeContext = nil
                }
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

    public func pmkAsync(execute body: @escaping () -> Void) {
        var expired: Bool!
        barrier.sync {
            expired = self.context.expired
        }
        if expired && Thread.isMainThread {
            body()
        } else {
            // these blocks are added to a pool and executed sequentially
            // when the next main runloop iteration occurs
            DispatchQueue.main.async(execute: body)
        }
    }
}
