//
//  AVFoundation+AnyPromise.h
//
//  Created by Matthew Loseke on 6/21/14.
//

#import <AVFoundation/AVFoundation.h>
#import <PromiseKit/AnyPromise.h>

/**
 To import the `AVAudioSession` category:

    use_frameworks!
    pod "PromiseKit/AVFoundation"

 And then in your sources:

    #import <PromiseKit/PromiseKit.h>
*/
@interface AVAudioSession (PromiseKit)

/**
 Wraps `-requestRecordPermission:`, thens the `BOOL granted` parameter
 passed to the wrapped completion block. This promise cannot fail.

 @see requestRecordPermission:
*/
- (AnyPromise *)requestRecordPermission;

@end
