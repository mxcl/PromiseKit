import struct Foundation.TimeInterval
import Dispatch

/**
     after(.seconds(2)).then {
         //…
     }

- Returns: A guarantee that resolves after the specified duration.
*/
public func after(seconds: TimeInterval) -> Guarantee<Void> {
    let (rg, seal) = Guarantee<Void>.pending()
    let when = DispatchTime.now() + seconds
#if swift(>=4.0)
    q.asyncAfter(deadline: when) { seal(()) }
#else
    q.asyncAfter(deadline: when, execute: seal)
#endif
    return rg
}

/**
     after(seconds: 1.5).then {
         //…
     }

 - Returns: A guarantee that resolves after the specified duration.
*/
public func after(_ interval: DispatchTimeInterval) -> Guarantee<Void> {
    let (rg, seal) = Guarantee<Void>.pending()
    let when = DispatchTime.now() + interval
#if swift(>=4.0)
    q.asyncAfter(deadline: when) { seal(()) }
#else
    q.asyncAfter(deadline: when, execute: seal)
#endif
    return rg
}

private var q: DispatchQueue {
    if #available(macOS 10.10, iOS 8.0, tvOS 9.0, watchOS 2.0, *) {
        return DispatchQueue.global(qos: .default)
    } else {
        return DispatchQueue.global(priority: .default)
    }
}
