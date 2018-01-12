//
//  AVFoundation+PromiseKit.h
//
//  Created by Matthew Loseke on 6/21/14.
//

#import <AVFoundation/AVFoundation.h>
#import <PromiseKit/fwd.h>

/**
 To import the `AVAudioSession` category:

    pod "PromiseKit/AVAudioSession"

 Or you can import all categories on `AVFoundation`:

    pod "PromiseKit/AVFoundation"
*/
@interface AVAudioSession (PromiseKit)

- (PMKPromise *)promiseForRequestRecordPermission PMK_DEPRECATED("Use -requestRecordPermission");

/**
 Wraps `-requestRecordPermission:`, thens the `BOOL granted` parameter
 passed to the wrapped completion block. This promise cannot fail.

 @see requestRecordPermission:
 */
- (PMKPromise *)requestRecordPermission;

@end
