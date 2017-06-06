@import Foundation;
@class AnyPromise;

AnyPromise *PMKDummyAnyPromise_YES(void);
AnyPromise *PMKDummyAnyPromise_Manifold(void);
AnyPromise *PMKDummyAnyPromise_Error(void);

__attribute__((objc_runtime_name("PMKPromiseBridgeHelper")))
__attribute__((objc_subclassing_restricted))
@interface PromiseBridgeHelper: NSObject
- (AnyPromise *)bridge1;
@end

AnyPromise *testCase626(void);
