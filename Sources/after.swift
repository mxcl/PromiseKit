import struct Foundation.TimeInterval
import Dispatch


/// Extend DispatchWorkItem to be a CancellableTask
extension DispatchWorkItem: CancellableTask { }

/**
     after(seconds: 1.5).then {
         //…
     }

- Returns: A guarantee that resolves after the specified duration.
- Note: cancelling this guarantee will cancel the underlying timer task
- SeeAlso: [Cancellation](http://promisekit.org/docs/)
*/
public func after(seconds: TimeInterval) -> Guarantee<Void> {
    let (rg, seal) = Guarantee<Void>.pending()
    let when = DispatchTime.now() + seconds
    let task = DispatchWorkItem { seal(()) }
    rg.setCancellableTask(task)
    q.asyncAfter(deadline: when, execute: task)
    return rg
}

/**
     after(.seconds(2)).then {
         //…
     }

 - Returns: A guarantee that resolves after the specified duration.
 - Note: cancelling this guarantee will cancel the underlying timer task
 - SeeAlso: [Cancellation](http://promisekit.org/docs/)
*/
public func after(_ interval: DispatchTimeInterval) -> Guarantee<Void> {
    let (rg, seal) = Guarantee<Void>.pending()
    let when = DispatchTime.now() + interval
    let task = DispatchWorkItem { seal(()) }
    rg.setCancellableTask(task)
    q.asyncAfter(deadline: when, execute: task)
    return rg
}

private var q: DispatchQueue {
    if #available(macOS 10.10, iOS 8.0, tvOS 9.0, watchOS 2.0, *) {
        return DispatchQueue.global(qos: .default)
    } else {
        return DispatchQueue.global(priority: .default)
    }
}
