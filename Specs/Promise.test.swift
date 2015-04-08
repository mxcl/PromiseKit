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
        Promise<Int>{ (fulfiller, rejecter) -> Void in
            rejecter(NSError(domain: PMKErrorDomain, code: 123, userInfo: nil))
        }.catch { (err:NSError) -> Int in
            return 123  //TODO return err.code
        }.then{ (value: Int) -> Void in
            XCTAssertEqual(value, 123)
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
            XCTAssertEqual(err.domain, PMKErrorDomain)
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
            XCTAssertEqual(err.code, 123)
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

    func testCanCatchOffVoidPromise() {
        let e1 = expectation()

        let p1 = Promise<Int>{ _, reject in
            reject(dammy)
        }
        let p2 = p1.then{ (number: Int)->Void in
            let a = "int is \(number)"
        }
        let p3 = p2.then{ Void->Void in
            let a = 1
            return
        }

        // Due to Swift finding this situation ambiguous we have to explicitly
        // tell it which catch to use. As yet I’m not sure of a good solution.
        // see: https://github.com/mxcl/PromiseKit/issues/56

        let q = dispatch_get_global_queue(0, 0)
        let catch = p3.catch as (dispatch_queue_t, (err:NSError)->())->()
        catch(q) { err in
            e1.fulfill()
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testZalgo() {
        var resolved = false
        Promise(value: 1).thenUnleashZalgo{ x in
            resolved = true
        }
        XCTAssertTrue(resolved)
    }

    func testWhenAnyObject() {
        let e1 = expectation()
        let p1 = Promise(value: 1 as AnyObject)
        let p2 = Promise(value: 2 as AnyObject)
        let p3 = Promise(value: 3 as AnyObject)
        let p4 = Promise(value: 4 as AnyObject)

        when(p1, p2, p3, p4).then { (x: [AnyObject])->() in
            XCTAssertEqual(x[0] as! Int, 1)
            XCTAssertEqual(x[1] as! Int, 2)
            XCTAssertEqual(x[2] as! Int, 3)
            XCTAssertEqual(x[3] as! Int, 4)
            XCTAssertEqual(x.count, 4)
            e1.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testWhen2() {
        let e1 = expectation()
        let p1 = Promise(value: 1)
        let p2 = Promise(value: "abc")
        when(p1, p2).then{ (x: Int, y: String)->() in
            XCTAssertEqual(x, 1)
            XCTAssertEqual(y, "abc")
            e1.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testWhenVoid() {
        let e1 = expectation()
        let p1 = Promise(value: 1).then{ x->Void in }
        let p2 = Promise(value: 2).then{ x->Void in }
        let p3 = Promise(value: 3).then{ x->Void in }
        let p4 = Promise(value: 4).then{ x->Void in }

        when([p1, p2, p3, p4]).then{
            e1.fulfill()
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testZalgoMore() {
        let p1 = Promise(value: 1).thenUnleashZalgo{ x->Int in
            return 2
        }
        XCTAssertEqual(p1.value!, 2)

        var x = 0

        let (p2, f, _) = Promise<Int>.defer()
        p2.thenUnleashZalgo{ _->Void in
            x = 1
        }
        XCTAssertEqual(x, 0)

        f(1)
        XCTAssertEqual(x, 1)
    }

    func testRace1() {
        let ex = expectation()
        race(after(0.01), after(1.0)).then { (interval: NSTimeInterval, index: Int) -> Void in
            XCTAssertEqual(index, 0)
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testRace2() {
        let ex = expectation()
        race(after(1.0), after(0.01)).then { (interval: NSTimeInterval, index: Int) -> Void in
            XCTAssertEqual(index, 1)
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
