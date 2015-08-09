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

- (void)testPMKSetJSONMimeTypes {
    id stubData = [@"{\"a\": \"b\"}" dataUsingEncoding:NSUTF8StringEncoding];

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *rq){
        return [rq.URL.host isEqualToString:@"example.com"];
    } withStubResponse:^(NSURLRequest *request){
        return [OHHTTPStubsResponse responseWithData:stubData statusCode:200 headers:@{@"Content-Type": @"foo/bar"}];
    }];

    // Set the content type foo/bar to be the only JSON MIME type.

    PMKSetJSONMIMETypes(@[@"foo/bar"]);
    id ex = [self expectationWithDescription:@""];

    [NSURLConnection GET:[NSURL URLWithString:@"http://example.com"]].then(^(NSDictionary *object){
        XCTAssert([object isKindOfClass:[NSDictionary class]]);
        XCTAssertEqualObjects(object, (@{@"a": @"b"}));
    }).catch(^(NSError *error){
        XCTFail(@"catch(^(NSError *error): %@", error);
    }).finally(^{
        [ex fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
    PMKSetJSONMIMETypes(nil);

    // Reset the MIME types and ensure the content is note deserialized.

    ex = [self expectationWithDescription:@""];

    [NSURLConnection GET:[NSURL URLWithString:@"http://example.com"]].then(^(NSData *object){
        XCTAssert([object isKindOfClass:[NSData class]]);
        XCTAssertEqualObjects(object, [@"{\"a\": \"b\"}" dataUsingEncoding:NSUTF8StringEncoding]);
    }).catch(^(NSError *error){
        XCTFail(@"catch(^(NSError *error): %@", error);
    }).finally(^{
        [ex fulfill];
    });

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
