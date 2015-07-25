#import "AVAudioSession+AnyPromise.h"
@import AVFoundation;
@import XCTest;

@implementation Test_AVAudioSession_ObjC: XCTestCase

- (void)test {
    id ex = [self expectationWithDescription:@""];

    [[AVAudioSession new] requestRecordPermission].then(^{
        [ex fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
