@import Foundation;
@class AnyPromise;

AnyPromise *PMKDummyAnyPromise_YES();
AnyPromise *PMKDummyAnyPromise_Manifold();
AnyPromise *PMKDummyAnyPromise_Error();

__attribute__((objc_runtime_name("PMKPromiseBridgeHelper")))
__attribute__((objc_subclassing_restricted))
@interface PromiseBridgeHelper: NSObject
- (AnyPromise *)bridge1;
@end
