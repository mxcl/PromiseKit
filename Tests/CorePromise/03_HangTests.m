@import PromiseKit;
@import XCTest;

@interface HangTests: XCTestCase @end @implementation HangTests

- (void)test {
    __block int x = 0;
    id value = PMKHang(PMKAfter(0.02).then(^{ x++; return 1; }));
    XCTAssertEqual(x, 1);
    XCTAssertEqualObjects(value, @1);
}

@end
