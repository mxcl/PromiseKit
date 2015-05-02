#import "AnyPromise+Private.h"
@import Foundation.NSDictionary;
#import "PMKPromise.h"
#import "PromiseKit.h"

#ifndef PMKLog
#define PMKLog NSLog
#endif


@implementation PMKPromise (BackCompat)

+ (instancetype)new:(void(^)(PMKFulfiller, PMKRejecter))block {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        id rejecter = ^(id error){
            if (error == nil) {
                error = [NSError errorWithDomain:PMKErrorDomain code:PMKInvalidUsageError userInfo:nil];
            } else if (IsPromise(error)) {
                error = ((PMKPromise *)error).value;
            }
            if (!IsError(error)) {
                id userInfo = @{
                    NSLocalizedDescriptionKey: [error description],
                    NSUnderlyingErrorKey: error
                };
                error = [NSError errorWithDomain:PMKErrorDomain code:PMKInvalidUsageError userInfo:userInfo];
            }
            resolve(error);
        };

        id fulfiller = ^(id result){
            if (IsError(result))
                PMKLog(@"PromiseKit: Warning: PMKFulfiller called with NSError.");
            resolve(result);
        };

        @try {
            block(fulfiller, rejecter);
        } @catch (id thrown) {
            resolve(PMKProcessUnhandledException(thrown));
        }
    }];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"

+ (PMKPromise *)until:(id (^)(void))blockReturningPromises catch:(id)failHandler {
    return [PMKPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        __block void (^block)() = ^{
            AnyPromise *next = PMKWhen(blockReturningPromises());
            next.then(^(id o){
                resolve(o);
                block = nil;
            });
            next.catch(^(NSError *error){
                [AnyPromise promiseWithValue:error].catch(failHandler).then(block).catch(^{
                    resolve(error);
                    block = nil;
                });
            });
        };
        block();
    }];
}

#pragma clang diagnostic pop

@end



@implementation PMKPromise (Deprecated)

+ (PMKPromise *)when:(id)input {
    return PMKWhen(input);
}

+ (PMKPromise *)pause:(NSTimeInterval)duration {
    return PMKAfter(duration);
}

+ (PMKPromise *)join:(id)input {
    return PMKJoin(input).then(^(id a, id b, id c){
        // preserving PMK 1.x behavior
        return PMKManifold(b, c);
    });
}

@end
