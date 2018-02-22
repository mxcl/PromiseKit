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
        return [PMKPromise promiseWithValue:promises];

    // Keep a reference to the newly created
    // promise so we can check if it's resolved
    // when one of the passed in promises fails.
    __block PMKPromise *newPromise = nil;

    #define rejecter(key) ^(NSError *err){ \
        if (newPromise.resolved) \
            return; \
        id userInfo = err.userInfo.mutableCopy; \
        userInfo[PMKFailingPromiseIndexKey] = key; \
        err = [NSError errorWithDomain:err.domain code:err.code userInfo:userInfo]; \
        rejecter(err); \
    }

    if ([promises isKindOfClass:[NSDictionary class]])
        return newPromise = [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter){
            NSDictionary *promiseDictionary = (NSDictionary *) promises;
            NSMutableDictionary *results = [NSMutableDictionary new];
            for (id key in promiseDictionary) {
                PMKPromise *promise = promiseDictionary[key];
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

    return newPromise = [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter){
        NSPointerArray *results = nil;
      #if TARGET_OS_IPHONE
        results = [NSPointerArray strongObjectsPointerArray];
      #else
        if ([[NSPointerArray class] respondsToSelector:@selector(strongObjectsPointerArray)]) {
            results = [NSPointerArray strongObjectsPointerArray];
        } else {
          #pragma clang diagnostic push
          #pragma clang diagnostic ignored "-Wdeprecated-declarations"
            results = [NSPointerArray pointerArrayWithStrongObjects];
          #pragma clang diagnostic pop
        }
      #endif
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
