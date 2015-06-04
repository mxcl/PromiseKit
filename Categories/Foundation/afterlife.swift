import Foundation
import PromiseKit

private var handle: UInt8 = 0

private class GrimReaper: NSObject {
    deinit {
        fulfill()
    }
    let (promise, fulfill, _) = Promise<Void>.defer()
}

public func afterlife(object: NSObject) -> Promise<Void> {
    var reaper = objc_getAssociatedObject(object, &handle) as? GrimReaper
    if reaper == nil {
        reaper = GrimReaper()
        objc_setAssociatedObject(object, &handle, reaper, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
    }
    return reaper!.promise
}
