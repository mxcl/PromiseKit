@import Foundation;
@import ObjectiveC.runtime;


void *PMKManualReferenceAssociatedObject = &PMKManualReferenceAssociatedObject;


void PMKRetain(NSObject *obj) {
    objc_setAssociatedObject(obj, PMKManualReferenceAssociatedObject, obj, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

void PMKRelease(NSObject *obj) {
    objc_setAssociatedObject(obj, PMKManualReferenceAssociatedObject, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
