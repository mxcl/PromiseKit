//
//  AVAudioSession+PromiseKit.m
//
//  Created by Matthew Loseke on 6/21/14.
//

#import "AVAudioSession+PromiseKit.h"
#import "PromiseKit/Promise.h"

@implementation AVAudioSession (PromiseKit)

- (PMKPromise *)promiseForRequestRecordPermission
{
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            fulfiller([NSNumber numberWithBool:granted]);
        }];
    }];
}

@end
