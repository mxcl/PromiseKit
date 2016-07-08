@import Foundation.NSError;
@import Foundation.NSPointerArray;

#if TARGET_OS_IPHONE
    #define NSPointerArrayMake(N) ({ \
        NSPointerArray *aa = [NSPointerArray strongObjectsPointerArray]; \
        aa.count = N; \
        aa; \
    })
#else
    static inline NSPointerArray * __nonnull NSPointerArrayMake(NSUInteger count) {
      #pragma clang diagnostic push
      #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        NSPointerArray *aa = [[NSPointerArray class] respondsToSelector:@selector(strongObjectsPointerArray)]
            ? [NSPointerArray strongObjectsPointerArray]
            : [NSPointerArray pointerArrayWithStrongObjects];
      #pragma clang diagnostic pop
        aa.count = count;
        return aa;
    }
#endif

#define IsError(o) [o isKindOfClass:[NSError class]]
#define IsPromise(o) [o isKindOfClass:[AnyPromise class]]

#import "AnyPromise.h"

@interface AnyPromise (Swift)
- (AnyPromise * __nonnull)__thenOn:(__nonnull dispatch_queue_t)q execute:(id __nullable (^ __nonnull)(id __nullable))body;
- (AnyPromise * __nonnull)__catchWithPolicy:(PMKCatchPolicy)policy execute:(id __nullable (^ __nonnull)(id __nullable))body;
- (AnyPromise * __nonnull)__alwaysOn:(__nonnull dispatch_queue_t)q execute:(void (^ __nonnull)(void))body;
- (void)__pipe:(void(^ __nonnull)(__nullable id))body;
- (AnyPromise * __nonnull)initWithResolverBlock:(void (^ __nonnull)(PMKResolver __nonnull))resolver;
@end

extern NSError * __nullable PMKProcessUnhandledException(id __nonnull thrown);

// TODO really this is not valid, we should instead nest the errors with NSUnderlyingError
// since a special error subclass may be being used and we may not set it up correctly
// with our copy
#define NSErrorSupplement(_err, supplements) ({ \
    NSError *err = _err; \
    id userInfo = err.userInfo.mutableCopy ?: [NSMutableArray new]; \
    [userInfo addEntriesFromDictionary:supplements]; \
    [[[err class] alloc] initWithDomain:err.domain code:err.code userInfo:userInfo]; \
})
