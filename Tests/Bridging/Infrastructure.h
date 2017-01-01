@import Foundation;
@class AnyPromise;

AnyPromise * __nonnull PMKDummyAnyPromise_YES();
AnyPromise * __nonnull PMKDummyAnyPromise_Manifold();
AnyPromise * __nonnull PMKDummyAnyPromise_Error();

__attribute__((objc_runtime_name("PMKPromiseBridgeHelper")))
__attribute__((objc_subclassing_restricted))
@interface PromiseBridgeHelper: NSObject
- (AnyPromise * __nonnull)bridge1;
@end
