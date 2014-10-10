#import "PromiseKit/Promise.h"
#import "PromiseKit/Promise+When.h"


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"


@implementation PMKPromise (Until)

+ (PMKPromise *)until:(id (^)(void))blockReturningPromises catch:(id)failHandler
{
    return [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject){
        __block void (^block)() = ^{
            PMKPromise *next = [self when:blockReturningPromises()];
            next.then(^(id o){
                fulfill(o);
                block = nil;  // break retain cycle
            });
            next.catch(^(NSError *error){
                [PMKPromise promiseWithValue:error].catch(failHandler).then(block).catch(^{
                    reject(error);
                    block = nil;  // break retain cycle
                });
            });
        };
        block();
    }];
}

@end
