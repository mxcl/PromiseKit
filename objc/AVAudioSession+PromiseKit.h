//
//  AVFoundation+PromiseKit.h
//
//  Created by Matthew Loseke on 6/21/14.
//

#import <AVFoundation/AVAudioSession.h>


@class PMKPromise;

@interface AVAudioSession (PromiseKit)

- (PMKPromise *)promiseForRequestRecordPermission;

@end
