#import "AnyPromise.h"
#import "AnyPromise+Private.h"
@import Foundation.NSDictionary;
@import Foundation.NSError;
@import Foundation.NSNull;
#import <PromiseKit/Umbrella.h>

@implementation AnyPromise (join)

AnyPromise *PMKJoin(NSArray *promises) {
    if (promises == nil)
        return [AnyPromise promiseWithValue:[NSError errorWithDomain:PMKErrorDomain code:PMKInvalidUsageError userInfo:@{NSLocalizedDescriptionKey: @"PMKJoin(nil)"}]];

    if (promises.count == 0)
        return [AnyPromise promiseWithValue:PMKManifold(promises, promises)];

    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        NSPointerArray *results = NSPointerArrayMake(promises.count);

        __block NSUInteger x = 0;

        [promises enumerateObjectsUsingBlock:^(AnyPromise *promise, NSUInteger ii, BOOL *stop) {
            [promise pipe:^(id value) {
                [results replacePointerAtIndex:ii withPointer:(__bridge void *)(value ?: [NSNull null])];
                if (++x == promises.count) {
                    id apples = results.allObjects;
                    id values = [NSMutableArray new];
                    id errors = [NSMutableArray new];
                    for (id apple in apples)
                        [IsError(apple) ? errors : values addObject:apple];
                    if ([errors count] == 0)
                        errors = nil;
                    resolve(PMKManifold(apples, values, errors));
                }
            }];
        }];
    }];
}

@end
