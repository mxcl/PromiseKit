import struct Foundation.TimeInterval
import Dispatch

/**
 - Returns: A `Guarantee` that resolves after the specified duration.
*/
public func after(interval: TimeInterval) -> Guarantee<Void> {
    let (guarantee, seal) = Guarantee<Void>.pending()
    DispatchQueue.global().asyncAfter(deadline: .now() + interval, execute: seal)
    return guarantee
}
