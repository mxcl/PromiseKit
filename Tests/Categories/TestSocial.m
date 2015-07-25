#import "SLRequest+AnyPromise.h"
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


@implementation Test_SLRequest_ObjC: XCTestCase

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


#ifndef TARGET_OS_MAC

#import <PromiseKit/NSError+Cancellation.h>
@import Social.SLComposeViewController;
@import Stubbilino;
#import "UIViewController+AnyPromise.h"

@implementation Test_SLComposeViewController_ObjC: XCTestCase

- (void)__test:(SLComposeViewControllerResult)dummy :(void (^)(AnyPromise *, id expectation))block {
    id rootvc = [UIViewController new];
    id ex = [self expectationWithDescription:@""];

    SLComposeViewController *composevc = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];

    id stub = [Stubbilino stubObject:rootvc];
    [stub stubMethod:@selector(presentViewController:animated:completion:) withBlock:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            composevc.completionHandler(dummy);
        });
    }];

    block([rootvc promiseViewController:composevc animated:NO completion:nil], ex);

    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test1 {
    NSInteger dummy = SLComposeViewControllerResultDone;

    [self __test:dummy :^(AnyPromise *promise, id expectation) {
        promise.then(^(id result){
            XCTAssertEqual([result integerValue], dummy);
            [expectation fulfill];
        });
    }];
}

- (void)test2 {
    [self __test:SLComposeViewControllerResultCancelled :^(AnyPromise *promise, id expectation) {
        promise.catchWithPolicy(PMKCatchPolicyAllErrors, ^(NSError *error){
            XCTAssertTrue(error.cancelled);
            [expectation fulfill];
        });
    }];
}

@end

#endif
