#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import "PromiseKit/Promise+Until.h"
#import "PromiseKit/Promise+WhenResolved.h"


@implementation PMKPromise (WhenResolved)

+ (PMKPromise *)whenResolved:(NSArray*)promises {
    __block NSMutableArray *mutablePromises = [promises mutableCopy];
    __block NSMutableArray *collectedErrors = [NSMutableArray new];

    return [PMKPromise until:^id { return mutablePromises; }
                       catch:^(NSError *error) {
        [collectedErrors addObject:error];
        [mutablePromises removeObjectAtIndex:[error.userInfo[PMKFailingPromiseIndexKey] unsignedIntegerValue]];
    }].then(^id(id fulfilledResults) {
        return PMKManifold(fulfilledResults, (collectedErrors.count ? collectedErrors : nil));
    });
}

@end
