import ObjectiveC.runtime;

private let ref = UnsafePointer<Void>()
private let policy = UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC) as objc_AssociationPolicy

func PMKRetain(obj: AnyObject) {
    objc_setAssociatedObject(obj, ref, obj, policy)
}

func PMKRelease(obj: AnyObject) {
    let n: AnyObject? = nil
    objc_setAssociatedObject(obj, ref, n!, policy)
}
