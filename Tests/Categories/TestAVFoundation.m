#import "AVAudioSession+AnyPromise.h"
@import AVFoundation;
@import XCTest;


@interface TestAVAudioSession: XCTestCase @end @implementation TestAVAudioSession

- (void)test {
    id ex = [self expectationWithDescription:@""];

    [[AVAudioSession new] requestRecordPermission].then(^{
        [ex fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
