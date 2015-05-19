#import "AnyPromise.h"
#import "AnyPromise+Private.h"
@import Foundation.NSDictionary;
@import Foundation.NSError;
@import Foundation.NSProgress;
@import Foundation.NSNull;
#import "Umbrella.h"

// NSProgress resources:
//  * https://robots.thoughtbot.com/asynchronous-nsprogress
//  * http://oleb.net/blog/2014/03/nsprogress/
// NSProgress! Beware!
//  * https://github.com/AFNetworking/AFNetworking/issues/2261


AnyPromise *PMKWhen(id promises) {
    if (promises == nil)
        return [AnyPromise promiseWithValue:[NSError errorWithDomain:PMKErrorDomain code:PMKInvalidUsageError userInfo:@{NSLocalizedDescriptionKey: @"PMKWhen(nil)"}]];

    if ([promises isKindOfClass:[NSArray class]] || [promises isKindOfClass:[NSDictionary class]]) {
        if ([promises count] == 0)
            return [AnyPromise promiseWithValue:promises];
    } else if ([promises isKindOfClass:[AnyPromise class]]) {
        promises = @[promises];
    } else {
        return [AnyPromise promiseWithValue:promises];
    }

#ifndef PMKDisableProgress
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:[promises count]];
    progress.pausable = NO;
    progress.cancellable = NO;
#endif

    PMKResolver resolve;
    AnyPromise *rootPromise = [[AnyPromise alloc] initWithResolver:&resolve];
    __block void (^fulfill)();

    __block NSInteger countdown = [promises count];
    void (^yield)(id, id, void(^)(id)) = ^(AnyPromise *promise, id key, void(^set)(id)) {
        if (![promise isKindOfClass:[AnyPromise class]])
            promise = [AnyPromise promiseWithValue:promise];
        [promise pipe:^(id value){
            if (!rootPromise.pending) {
                // suppress “already resolved” log message
            } else if (IsError(value)) {
              #ifndef PMKDisableProgress
                progress.completedUnitCount = progress.totalUnitCount;
              #endif
                resolve(NSErrorSupplement(value, @{PMKFailingPromiseIndexKey: key}));
            } else {
              #ifndef PMKDisableProgress
                progress.completedUnitCount++;
              #endif
                set(value);
                if (--countdown == 0)
                    fulfill();
            }
        }];
    };

    if ([promises isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *results = [NSMutableDictionary new];
        fulfill = ^{ resolve(results); };

        for (id key in promises) {
            yield(promises[key], key, ^(id value){
                results[key] = value;
            });
        }
    } else {
        NSPointerArray *results = NSPointerArrayMake([promises count]);
        fulfill = ^{ resolve(results.allObjects); };

        [promises enumerateObjectsUsingBlock:^(id promise, NSUInteger ii, BOOL *stop) {
            yield(promise, @(ii), ^(id value){
                [results replacePointerAtIndex:ii withPointer:(__bridge void *)(value ?: [NSNull null])];
            });
        }];
    }
    
    return rootPromise;
}
