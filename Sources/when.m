#import "AnyPromise.h"
#import "AnyPromise+Private.h"
@import Foundation.NSDictionary;
@import Foundation.NSError;
@import Foundation.NSNull;
#import "Umbrella.h"

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

    PMKResolver resolve;
    AnyPromise *rootPromise = [AnyPromise promiseWithResolver:&resolve];
    __block void (^fulfill)();

    __block NSInteger countdown = [promises count];
    void (^yield)(id, id, void(^)(id)) = ^(AnyPromise *promise, id key, void(^set)(id)) {
        if (![promise isKindOfClass:[AnyPromise class]])
            promise = [AnyPromise promiseWithValue:promise];
        [promise pipe:^(id value){
            if (!rootPromise.pending) {
                // suppress “already resolved” log message
            } else if (IsError(value)) {
                NSError *err = value;
                id userInfo = err.userInfo.mutableCopy;
                userInfo[PMKFailingPromiseIndexKey] = key;
                //TODO add test that when etc. don't lose NSError class
                err = [[[value class] alloc] initWithDomain:err.domain code:err.code userInfo:userInfo];
                resolve(err);
            } else {
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
