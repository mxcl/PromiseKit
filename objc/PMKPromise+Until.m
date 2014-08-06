@import Foundation;
#import "PromiseKit/Promise.h"
#import "PromiseKit/Promise+When.h"


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"


@implementation PMKPromise (Until)

+ (PMKPromise *)until:(id (^)(void))blockReturningPromises catch:(id)failHandler
{
    return [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject){
        __block void (^block)() = ^{
            PMKPromise *next = [self when:blockReturningPromises()].then(^(id o){
                fulfill(o);
                block = nil;  // break retain cycle
            }).catch(failHandler);

            next.then(block);
            next.catch(^(id err){
                // we documented that the loop ends, the returned promise
                // is not rejected. But probably should revisit that.
                //reject(err);
                block = nil;  // break retain cycle
            });
        };
        block();
    }];
}

@end
