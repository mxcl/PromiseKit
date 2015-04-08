import ObjectiveC.runtime
import Foundation.NSOperation

let Q = NSOperationQueue()

private var asskey = "PMKSfjadfl"
private let policy = UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC) as objc_AssociationPolicy

func PMKRetain(obj: AnyObject) {
    objc_setAssociatedObject(obj, &asskey, obj, policy)
}

func PMKRelease(obj: AnyObject) {
    objc_setAssociatedObject(obj, &asskey, nil, policy)
}
