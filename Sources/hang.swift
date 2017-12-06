import Foundation
import CoreFoundation

/**
 Suspends the active thread waiting on the provided promise.

 Useful when an application's main thread should not terminate before the promise is resolved
 (e.g. commandline applications).

 - Returns: The value of the provided promise once resolved.
 - Throws: An error, should the promise be resolved with an error.
 - SeeAlso: `wait()`
*/
public func hang<T>(_ promise: Promise<T>) throws -> T {
#if os(Linux)
    // isMainThread is not yet implemented on Linux.
    let runLoopModeRaw = RunLoopMode.defaultRunLoopMode.rawValue._bridgeToObjectiveC()
    let runLoopMode: CFString = unsafeBitCast(runLoopModeRaw, to: CFString.self)
#else
    guard Thread.isMainThread else {
        // hang doesn't make sense on threads that aren't the main thread.
        // use `.wait()` on those threads.
        fatalError("Only call hang() on the main thread.")
    }
    let runLoopMode: CFRunLoopMode = CFRunLoopMode.defaultMode
#endif

    if promise.isPending {
        var context = CFRunLoopSourceContext()
        let runLoop = CFRunLoopGetCurrent()
        let runLoopSource = CFRunLoopSourceCreate(nil, 0, &context)
        CFRunLoopAddSource(runLoop, runLoopSource, runLoopMode)

        _ = promise.ensure {
            CFRunLoopStop(runLoop)
        }

        while promise.isPending {
            CFRunLoopRun()
        }
        CFRunLoopRemoveSource(runLoop, runLoopSource, runLoopMode)
    }

    switch promise.result! {
    case .rejected(let error):
        throw error
    case .fulfilled(let value):
        return value
    }
}
