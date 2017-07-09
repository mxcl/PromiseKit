import PromiseKit
import XCTest

class WhenTests: XCTestCase {

    func testEmpty() {
        let e = expectation(description: "")
        let promises: [Promise<Void>] = []
        when(fulfilled: promises).then { _ in
            e.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testInt() {
        let e1 = expectation(description: "")
        let p1 = Promise(value: 1)
        let p2 = Promise(value: 2)
        let p3 = Promise(value: 3)
        let p4 = Promise(value: 4)

        when(fulfilled: [p1, p2, p3, p4]).then { (x: [Int])->() in
            XCTAssertEqual(x[0], 1)
            XCTAssertEqual(x[1], 2)
            XCTAssertEqual(x[2], 3)
            XCTAssertEqual(x[3], 4)
            XCTAssertEqual(x.count, 4)
            e1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testDoubleTuple() {
        let e1 = expectation(description: "")
        let p1 = Promise(value: 1)
        let p2 = Promise(value: "abc")
        when(fulfilled: p1, p2).then{ x, y -> Void in
            XCTAssertEqual(x, 1)
            XCTAssertEqual(y, "abc")
            e1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testTripleTuple() {
        let e1 = expectation(description: "")
        let p1 = Promise(value: 1)
        let p2 = Promise(value: "abc")
        let p3 = Promise(value: 1.0)
        when(fulfilled: p1, p2, p3).then { u, v, w -> Void in
            XCTAssertEqual(1, u)
            XCTAssertEqual("abc", v)
            XCTAssertEqual(1.0, w)
            e1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testQuadrupleTuple() {
        let e1 = expectation(description: "")
        let p1 = Promise(value: 1)
        let p2 = Promise(value: "abc")
        let p3 = Promise(value: 1.0)
        let p4 = Promise(value: true)
        when(fulfilled: p1, p2, p3, p4).then { u, v, w, x -> Void in
            XCTAssertEqual(1, u)
            XCTAssertEqual("abc", v)
            XCTAssertEqual(1.0, w)
            XCTAssertEqual(true, x)
            e1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testQuintupleTuple() {
        let e1 = expectation(description: "")
        let p1 = Promise(value: 1)
        let p2 = Promise(value: "abc")
        let p3 = Promise(value: 1.0)
        let p4 = Promise(value: true)
        let p5 = Promise(value: "a" as Character)
        when(fulfilled: p1, p2, p3, p4, p5).then { u, v, w, x, y -> Void in
            XCTAssertEqual(1, u)
            XCTAssertEqual("abc", v)
            XCTAssertEqual(1.0, w)
            XCTAssertEqual(true, x)
            XCTAssertEqual("a" as Character, y)
            e1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testVoid() {
        let e1 = expectation(description: "")
        let p1 = Promise(value: 1).then { x -> Void in }
        let p2 = Promise(value: 2).then { x -> Void in }
        let p3 = Promise(value: 3).then { x -> Void in }
        let p4 = Promise(value: 4).then { x -> Void in }

        when(fulfilled: p1, p2, p3, p4).then(execute: e1.fulfill)

        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testRejected() {
        enum Error: Swift.Error { case dummy }

        let e1 = expectation(description: "")
        let p1 = after(interval: .milliseconds(100)).then{ true }
        let p2 = after(interval: .milliseconds(200)).then{ throw Error.dummy }
        let p3 = Promise(value: false)
            
        when(fulfilled: p1, p2, p3).catch { _ in
            e1.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testProgress() {
        let ex = expectation(description: "")

        XCTAssertNil(Progress.current())

        let p1 = after(interval: .milliseconds(10))
        let p2 = after(interval: .milliseconds(20))
        let p3 = after(interval: .milliseconds(30))
        let p4 = after(interval: .milliseconds(40))

        let progress = Progress(totalUnitCount: 1)
        progress.becomeCurrent(withPendingUnitCount: 1)

        when(fulfilled: p1, p2, p3, p4).then { _ -> Void in
            XCTAssertEqual(progress.completedUnitCount, 1)
            ex.fulfill()
        }

        progress.resignCurrent()
        
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testProgressDoesNotExceed100Percent() {
        let ex1 = expectation(description: "")
        let ex2 = expectation(description: "")

        XCTAssertNil(Progress.current())

        let p1 = after(interval: .milliseconds(10))
        let p2: Promise<Void> = after(interval: .milliseconds(20)).then { throw NSError(domain: "a", code: 1, userInfo: nil) }
        let p3 = after(interval: .milliseconds(30))
        let p4 = after(interval: .milliseconds(40))

        let progress = Progress(totalUnitCount: 1)
        progress.becomeCurrent(withPendingUnitCount: 1)

        let promise: Promise<Void> = when(fulfilled: p1, p2, p3, p4)

        progress.resignCurrent()

        promise.catch { _ in
            ex2.fulfill()
        }

        var x = 0
        func finally() {
            x += 1
            if x == 4 {
                XCTAssertLessThanOrEqual(1, progress.fractionCompleted)
                XCTAssertEqual(progress.completedUnitCount, 1)
                ex1.fulfill()
            }
        }

        let q = DispatchQueue.main
        p1.always(on: q, execute: finally)
        p2.always(on: q, execute: finally)
        p3.always(on: q, execute: finally)
        p4.always(on: q, execute: finally)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testUnhandledErrorHandlerDoesNotFire() {
        enum Error: Swift.Error {
            case test
        }

        InjectedErrorUnhandler = { error in
            XCTFail()
        }

        let ex = expectation(description: "")
        let p1 = Promise<Void>(error: Error.test)
        let p2 = after(interval: .milliseconds(100))
        when(fulfilled: p1, p2).then{ XCTFail() }.catch { error in
            XCTAssertTrue(error as? Error == Error.test)
            ex.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testUnhandledErrorHandlerDoesNotFireForStragglers() {
        enum Error: Swift.Error {
            case test
            case straggler
        }

        InjectedErrorUnhandler = { error in
            XCTFail()
        }

        let ex1 = expectation(description: "")
        let ex2 = expectation(description: "")
        let ex3 = expectation(description: "")

        let p1 = Promise<Void>(error: Error.test)
        let p2 = after(interval: .milliseconds(100)).then { throw Error.straggler }
        let p3 = after(interval: .milliseconds(200)).then { throw Error.straggler }

        when(fulfilled: p1, p2, p3).catch { error -> Void in
            XCTAssertTrue(Error.test == error as? Error)
            ex1.fulfill()
        }

        p2.always { after(interval: .milliseconds(100)).then(execute: ex2.fulfill) }
        p3.always { after(interval: .milliseconds(100)).then(execute: ex3.fulfill) }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testAllSealedRejectedFirstOneRejects() {
        enum Error: Swift.Error {
            case test1
            case test2
            case test3
        }

        let ex = expectation(description: "")
        let p1 = Promise<Void>(error: Error.test1)
        let p2 = Promise<Void>(error: Error.test2)
        let p3 = Promise<Void>(error: Error.test3)

        when(fulfilled: p1, p2, p3).catch { error in
            XCTAssertTrue(error as? Error == Error.test1)
            ex.fulfill()
        }

        waitForExpectations(timeout: 1)
    }
}
