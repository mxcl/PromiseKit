//
//  AVFoundation+PromiseKit.h
//
//  Created by Matthew Loseke on 6/21/14.
//

#if PMK_MODULES
@import AVFoundation.AVAudioSession;
#else
#import <AVFoundation/AVFoundation.h>
#endif


@class PMKPromise;

@interface AVAudioSession (PromiseKit)

- (PMKPromise *)promiseForRequestRecordPermission;

@end
