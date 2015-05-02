#import "SLRequest+AnyPromise.h"
@import Social;
@import Stubbilino;
@import XCTest;


@interface MockSLRequest: SLRequest
@property id response;
@property id data;
@property id error;
@end
@implementation MockSLRequest
- (void)performRequestWithHandler:(SLRequestHandler)handler {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        handler(_data, _response, _error);
    });
}
@end


@interface TestSLRequestCategory: XCTestCase @end @implementation TestSLRequestCategory

- (void)test1 {
    id url = [NSURL URLWithString:@"http://example.com"];
    id input = @{@"3": @4};

    MockSLRequest *request = (id) [MockSLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:SLRequestMethodGET URL:url parameters:@{@"1": @2}];
    request.response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    request.data = [NSJSONSerialization dataWithJSONObject:input options:0 error:nil];

    id ex = [self expectationWithDescription:@""];
    [request promise].then(^(id json){
        XCTAssertEqualObjects(json, input);
        [ex fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test2 {
    id url = [NSURL URLWithString:@"http://example.com"];

    MockSLRequest *request = (id) [MockSLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:SLRequestMethodGET URL:url parameters:@{@"1": @2}];
    request.response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:500 HTTPVersion:@"1.1" headerFields:@{}];

    id ex = [self expectationWithDescription:@""];
    [request promise].catch(^(id err){
        XCTAssertEqualObjects(NSURLErrorDomain, [err domain]);
        XCTAssertEqual([err code], NSURLErrorBadServerResponse);
        [ex fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test3 {
    id url = [NSURL URLWithString:@"http://example.com"];
    id data = [NSData dataWithBytes:"abc" length:3];

    MockSLRequest *request = (id) [MockSLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:SLRequestMethodGET URL:url parameters:@{@"1": @2}];
    request.response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"1.1" headerFields:@{}];
    request.data = data;

    id ex = [self expectationWithDescription:@""];
    [request promise].then(^(id rspdata){
        XCTAssertEqualObjects(data, rspdata);
        [ex fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test4 {
    id url = [NSURL URLWithString:@"http://example.com"];

    MockSLRequest *request = (id) [MockSLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:SLRequestMethodGET URL:url parameters:@{@"1": @2}];
    request.response = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"1.1" headerFields:@{}];
    request.error = [NSError errorWithDomain:@"Cat" code:123 userInfo:nil];

    id ex = [self expectationWithDescription:@""];
    [request promise].catch(^(NSError *error){
        XCTAssertEqual(error.code, 123);
        XCTAssertEqualObjects(error.domain, @"Cat");
        [ex fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
