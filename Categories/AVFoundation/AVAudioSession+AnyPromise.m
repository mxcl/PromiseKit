//
//  AVAudioSession+PromiseKit.m
//
//  Created by Matthew Loseke on 6/21/14.
//

#import "AVAudioSession+AnyPromise.h"
#import <Foundation/Foundation.h>


@implementation AVAudioSession (PromiseKit)

- (AnyPromise *)requestRecordPermission {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            resolve(@(granted));
        }];
    }];
}

@end
