#import <Foundation/NSDictionary.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSPointerArray.h>
#import "PromiseKit/Promise+When.h"


@implementation PMKPromise (When)

+ (PMKPromise *)when:(id)promises {
    if ([promises conformsToProtocol:@protocol(NSFastEnumeration)]) {
        return [self all:promises];
    } else if (promises) {
        return [self all:@[promises]].then(^(NSArray *values){
            return values[0];
        });
    } else {
        return [PMKPromise promiseWithValue:nil];
    }
}

+ (PMKPromise *)all:(id<NSFastEnumeration, NSObject>)promises {
    __block NSUInteger count = [(id)promises count];  // FIXME
    
    if (count == 0)
        return [PMKPromise promiseWithValue:@[]];

    #define rejecter(key) ^(NSError *err){ \
        id userInfo = err.userInfo.mutableCopy; \
        userInfo[PMKFailingPromiseIndexKey] = key; \
        err = [NSError errorWithDomain:err.domain code:err.code userInfo:userInfo]; \
        rejecter(err); \
    }

    if ([promises isKindOfClass:[NSDictionary class]])
        return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter){
            NSMutableDictionary *results = [NSMutableDictionary new];
            for (id key in promises) {
                PMKPromise *promise = promises[key];
                if (![promise isKindOfClass:[PMKPromise class]])
                    promise = [PMKPromise promiseWithValue:promise];
                promise.catch(rejecter(key));
                promise.then(^(id o){
                    if (o)
                        results[key] = o;
                    if (--count == 0)
                        fulfiller(results);
                });
            }
        }];

    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter){
        NSPointerArray *results = [NSPointerArray strongObjectsPointerArray];
        results.count = count;

        NSUInteger ii = 0;

        for (__strong PMKPromise *promise in promises) {
            if (![promise isKindOfClass:[PMKPromise class]])
                promise = [PMKPromise promiseWithValue:promise];
            promise.catch(rejecter(@(ii)));
            promise.then(^(id o){
                [results replacePointerAtIndex:ii withPointer:(__bridge void *)(o ?: [NSNull null])];
                if (--count == 0)
                    fulfiller(results.allObjects);
            });
            ii++;
        }
    }];

    #undef rejecter
}

@end
