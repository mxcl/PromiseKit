@import ObjectiveC.runtime;

#import "PMKManualReference.h"

void * PMKManualReferenceAssociatedObject = &PMKManualReferenceAssociatedObject;

@implementation NSObject (PMKManualReference)
- (void)pmk_reference {
    objc_setAssociatedObject(self, PMKManualReferenceAssociatedObject, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)pmk_breakReference {
    objc_setAssociatedObject(self, PMKManualReferenceAssociatedObject, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end
