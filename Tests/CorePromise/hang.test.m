#import <PromiseKit/PromiseKit.h>
@import XCTest;

@interface HangTestCase: XCTestCase @end @implementation HangTestCase

- (void)test_77_hang {
    __block int x = 0;
    id value = PMKHang(PMKAfter(0.02).then(^{ x++; return 1; }));
    XCTAssertEqual(x, 1);
    XCTAssertEqualObjects(value, @1);
}

@end
