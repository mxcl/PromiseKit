@import Foundation;
#import "Infrastructure.h"

@implementation XCTestCase (PMKUnhandledErrorHandler)

+ (void)initialize {
    [Injected setUp];
}

- (void)setUp {
    Injected.errorUnhandler = ^(id err) {
        XCTFail("Unexpected unhandled error");
    };
}

@end
