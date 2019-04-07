import Foundation
import CoreFoundation

/**
 Runs the active run-loop until the provided promise resolves.

 This is for debug and is not a generally safe function to use in your applications. We mostly provide it for use in testing environments.

 Still if you like, study how it works (by reading the sources!) and use at your own risk.

 - Returns: The value of the resolved promise
 - Throws: An error, should the promise be rejected
 - See: `wait()`
*/
public func hang<T>(_ promise: Promise<T>) throws -> T {
#if os(Linux) || os(Android)
#if swift(>=4.2)
    let runLoopMode: CFRunLoopMode = kCFRunLoopDefaultMode
#else
    // isMainThread is not yet implemented on Linux.
    let runLoopModeRaw = RunLoopMode.defaultRunLoopMode.rawValue._bridgeToObjectiveC()
    let runLoopMode: CFString = unsafeBitCast(runLoopModeRaw, to: CFString.self)
#endif
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
