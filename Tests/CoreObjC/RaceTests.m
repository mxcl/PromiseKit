@import Foundation;
@import PromiseKit;
@import XCTest;
#define PMKTestErrorDomain @"PMKTestErrorDomain"

static inline NSError *dummyWithCode(NSInteger code) {
    return [NSError errorWithDomain:PMKTestErrorDomain code:rand() userInfo:@{NSLocalizedDescriptionKey: @(code).stringValue}];
}

@interface RaceTests : XCTestCase @end @implementation RaceTests

- (void)test_race {
    id ex = [self expectationWithDescription:@""];
    id p = PMKAfter(0.1).then(^{ return @2; });
    PMKRace(@[PMKAfter(10), PMKAfter(20), p]).then(^(id obj){
        XCTAssertEqual(2, [obj integerValue]);
        [ex fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_race_empty {
    id ex = [self expectationWithDescription:@""];
    PMKRace(@[]).then(^(NSArray* array){
        XCTFail();
        [ex fulfill];
    }).catch(^(NSError *e){
        XCTAssertEqual(e.domain, PMKErrorDomain);
        XCTAssertEqual(e.code, PMKInvalidUsageError);
        XCTAssertEqualObjects(e.userInfo[NSLocalizedDescriptionKey], @"PMKRace(nil)");
        [ex fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_race_fullfilled {
    id ex = [self expectationWithDescription:@""];
    NSArray* promises = @[
        PMKAfter(1).then(^{ return dummyWithCode(1); }),
        PMKAfter(2).then(^{ return dummyWithCode(2); }),
        PMKAfter(5).then(^{ return @1; }),
        PMKAfter(4).then(^{ return @2; }),
        PMKAfter(3).then(^{ return dummyWithCode(3); })
    ];
    PMKRaceFulfilled(promises).then(^(id obj){
        XCTAssertEqual(2, [obj integerValue]);
        [ex fulfill];
    }).catch(^{
        XCTFail();
        [ex fulfill];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)test_race_fulfilled_empty {
    id ex = [self expectationWithDescription:@""];
    PMKRaceFulfilled(@[]).then(^(NSArray* array){
        XCTFail();
        [ex fulfill];
    }).catch(^(NSError *e){
        XCTAssertEqual(e.domain, PMKErrorDomain);
        XCTAssertEqual(e.code, PMKInvalidUsageError);
        XCTAssertEqualObjects(e.userInfo[NSLocalizedDescriptionKey], @"PMKRaceFulfilled(nil)");
        [ex fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test_race_fullfilled_with_no_winner {
    id ex = [self expectationWithDescription:@""];
    NSArray* promises = @[
        PMKAfter(1).then(^{ return dummyWithCode(1); }),
        PMKAfter(2).then(^{ return dummyWithCode(2); }),
        PMKAfter(3).then(^{ return dummyWithCode(3); })
    ];
    PMKRaceFulfilled(promises).then(^(id obj){
        XCTFail();
        [ex fulfill];
    }).catch(^(NSError *e){
        XCTAssertEqual(e.domain, PMKErrorDomain);
        XCTAssertEqual(e.code, PMKNoWinnerError);
        XCTAssertEqualObjects(e.userInfo[NSLocalizedDescriptionKey], @"PMKRaceFulfilled(nil)");
        [ex fulfill];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

@end
