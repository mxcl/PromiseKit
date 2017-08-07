import struct Foundation.TimeInterval
import Dispatch

/**
     after(.seconds(2)).then {
         //…
     }

- Returns: A new promise that fulfills after the specified duration.
*/
public func after(seconds: TimeInterval) -> Guarantee<Void> {
    let (rg, seal) = Guarantee<Void>.pending()
    let when = DispatchTime.now() + seconds
#if swift(>=4.0)
    DispatchQueue.global().asyncAfter(deadline: when) { seal(()) }
#else
    DispatchQueue.global().asyncAfter(deadline: when, execute: seal)
#endif
    return rg
}

/**
     after(seconds: 1.5).then {
         //…
     }

 - Returns: A new promise that fulfills after the specified duration.
*/
public func after(_ interval: DispatchTimeInterval) -> Guarantee<Void> {
    let (rg, seal) = Guarantee<Void>.pending()
    let when = DispatchTime.now() + interval
#if swift(>=4.0)
    DispatchQueue.global().asyncAfter(deadline: when) { seal(()) }
#else
    DispatchQueue.global().asyncAfter(deadline: when, execute: seal)
#endif
    return rg
}
