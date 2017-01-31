import Foundation

public protocol ExecutionContext {
    // `pmk` prefix otherwise we leak our implementation details
    // all over the end-user’s project :(
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

//FIXME not thread-safe!!
class NextMainRunloop: ExecutionContext {
    private var context: Context
    private let key = "org.promisekit.exectx"

    class Context {
        var isReady = false
        var handlers = [() -> Void]()

        init() {
            DispatchQueue.main.async {
                self.isReady = true
                for handler in self.handlers {
                    handler()
                }

            }
        }
    }

    init() {  //FIXME needs locks
        if let ctx = Thread.main.threadDictionary[key] as? Context, ctx.isReady == false {
            context = ctx
        } else {
            context = Context()
            Thread.main.threadDictionary[key] = context
        }
    }

    public func pmkAsync(execute body: @escaping () -> Void) {  //FIXME needs locks
        if !context.isReady {
            context.handlers.append(body)
        } else {
            body()
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
