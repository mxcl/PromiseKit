#import <Foundation/Foundation.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <PromiseKit/PromiseKit.h>
#import "NSURLConnection+AnyPromise.h"
@import XCTest;


@interface TestNSURLConnectionM: XCTestCase @end @implementation TestNSURLConnectionM

- (void)tearDown {
    [OHHTTPStubs removeAllStubs];
}

- (void)test1 {
    id stubData = [NSData dataWithBytes:"[a: 3]" length:1];

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *rq){
        return [rq.URL.host isEqualToString:@"example.com"];
    } withStubResponse:^(NSURLRequest *request){
        return [OHHTTPStubsResponse responseWithData:stubData statusCode:200 headers:@{@"Content-Type": @"application/json"}];
    }];

    id ex = [self expectationWithDescription:@""];

    [NSURLConnection GET:[NSURL URLWithString:@"http://example.com"]].catch(^(NSError *err){
        XCTAssertEqualObjects(err.domain, NSCocoaErrorDomain);  //TODO this is why we should replace this domain
        XCTAssertEqual(err.code, 3840);
        XCTAssertEqualObjects(err.userInfo[PMKURLErrorFailingDataKey], stubData);
        XCTAssertNotNil(err.userInfo[PMKURLErrorFailingURLResponseKey]);
        [ex fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
