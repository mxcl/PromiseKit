import XCTest
import PromiseKit

extension XCTestCase {
    func expectation() -> XCTestExpectation {
        return expectationWithDescription("")
    }
}

class TestPromise: XCTestCase {
    var random:UInt32 = 0

    func sealed() -> Promise<UInt32> {
        random = arc4random()
        return Promise(value:random)
    }

    func unsealed() -> Promise<UInt32> {
        random = arc4random()

        return Promise<UInt32> { (fulfiller, rejecter) in
            dispatch_async(dispatch_get_main_queue()){
                fulfiller(self.random)
            }
        }
    }

    func test_hasValue() {
        let p:Promise<Int> = Promise(value:1)
        XCTAssertEqual(p.value!, 1)
    }

    func test_sealedCanThen() {
        let e1 = expectation()
        sealed().then { (v:UInt32) -> Void in
            XCTAssertEqual(v, self.random)
            e1.fulfill()
            return
        }
        waitForExpectationsWithTimeout(1, handler: nil)

        let e2 = expectation()
        sealed().then {
            XCTAssertEqual($0, self.random)
        }.then {
            e2.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test_unsealedCanThen() {
        let e1 = expectation()
        unsealed().then { (v:UInt32) -> Void in
            XCTAssertEqual(v, self.random)
            e1.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)

        let e2 = expectation()
        unsealed().then {
            XCTAssertEqual($0, self.random)
        }.then {
            e2.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)

        let e3 = expectation()
        unsealed().then {
            XCTAssertEqual($0, self.random)
        }.then { () -> Void in
            
        }.then {
            e3.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test_returnPromise() {
        let e1 = expectation()
        let e2 = expectation()
        sealed().then { (value) -> Promise<UInt32> in
            XCTAssertEqual(value, self.random)
            e1.fulfill()
            return self.unsealed()
        }.then { (value) -> Void in
            XCTAssertEqual(value, self.random)
            e2.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test_catch() {
        let e1 = expectation()
        Promise<UInt32>{ (_, rejecter) -> Void in
            rejecter(NSError(domain: PMKErrorDomain, code: 123, userInfo: [:]))
        }.catch { (err:NSError) -> Void in
            XCTAssertEqual(err.code, 123)
            e1.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test_f_catchAndContinue() {
        let e1 = expectation()
        Promise<UInt32>{ (fulfiller, rejecter) -> Void in
            rejecter(NSError(domain: PMKErrorDomain, code: 123, userInfo: [:]))
        }.catch { (err:NSError) -> UInt32 in
            return 123  //TODO return err.code
        }.then{ (value:UInt32) -> Void in
            XCTAssertEqual(123, value)
            e1.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test_finally() {
        let e1 = expectation()
        Promise<UInt32>{ (fulfiller, rejecter) in
            rejecter(NSError(domain: PMKErrorDomain, code: 123, userInfo: [:]))
        }.finally {
            e1.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)

        let e2 = expectation()
        Promise<Int>{ (fulfiller, rejecter) in
            fulfiller(123)
        }.finally {
            e2.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)

        let e3 = expectation()
        let e4 = expectation()

        Promise<UInt32>{ (fulfiller, rejecter) in
            rejecter(NSError(domain: PMKErrorDomain, code: 123, userInfo: [:]))
        }.finally {
            e3.fulfill()
        }.catch{ (err:NSError) -> Void in
            e4.fulfill()
            XCTAssertEqualObjects(err.domain, PMKErrorDomain)
        }
        waitForExpectationsWithTimeout(1, handler: nil)

        let e5 = self.expectationWithDescription("")
        let e6 = self.expectationWithDescription("")

        Promise<Int>{ (fulfiller, rejecter) in
            fulfiller(123)
        }.finally {
            e5.fulfill()
        }.then { (value:Int) -> Void in
            e6.fulfill()
            XCTAssertEqual(value, 123)
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test_008_thenOffVoid() {
        let e1 = expectation()
        unsealed().then { (value:UInt32) -> Void in
            return
        }.then { ()->() in
            e1.fulfill()
            return
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test_008_catchReturnsVoid() {
        let e1 = expectation()
        Promise<UInt32>{ (_, rejecter) in
            rejecter(NSError(domain: PMKErrorDomain, code: 123, userInfo: [:]))
        }.catch { (err:NSError)->() in
            XCTAssertEqualObjects(err.code, 123)
            e1.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testReturnSelfDoesntInfinitelyRecurseOrSomething() {
        let e1 = expectation()
        let p = unsealed()
        p.then { _-> Promise<UInt32> in
            return p
        }.then { _->() in
            e1.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
