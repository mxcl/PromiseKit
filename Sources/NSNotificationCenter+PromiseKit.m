#import <assert.h>
#import <Foundation/NSThread.h>
#import "NSNotificationCenter+PromiseKit.h"
#import <PromiseKit/Promise.h>


@implementation NSNotificationCenter (PromiseKit)

+ (PMKPromise *)once:(NSString *)name {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        __block id identifier = [[NSNotificationCenter defaultCenter] addObserverForName:name object:nil queue:PMKOperationQueue() usingBlock:^(NSNotification *note) {
            assert(!NSThread.isMainThread);

            [[NSNotificationCenter defaultCenter] removeObserver:identifier name:name object:nil];
            fulfiller(PMKManifold(note, note.userInfo));
        }];
    }];
}

@end
