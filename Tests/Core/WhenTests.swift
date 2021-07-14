@testable import PromiseKit
import Dispatch
import XCTest

class WhenTests: XCTestCase {
    func testEmpty() {
        let promises: [Promise<Void>] = []
        
        let ex = expectation(description: "")
        when(fulfilled: promises).done { _ in
            ex.fulfill()
        }.silenceWarning()

        let e2 = expectation(description: "")
        when(resolved: promises).done { _ in
            e2.fulfill()
        }

        waitForExpectations()
    }

    func testInt() {
        let ex = expectation(description: "")
        let e2 = expectation(description: "")
        let p1 = Promise.value(1)
        let p2 = Promise.value(2)
        let p3 = Promise.value(3)
        let p4 = Promise.value(4)

        when(fulfilled: [p1, p2, p3, p4]).done { x in
            XCTAssertEqual(x[0], 1)
            XCTAssertEqual(x[1], 2)
            XCTAssertEqual(x[2], 3)
            XCTAssertEqual(x[3], 4)
            XCTAssertEqual(x.count, 4)
            ex.fulfill()
        }.silenceWarning()
        
        when(resolved: [p1, p2, p3, p4]).done { x in
            XCTAssertEqual(try x[0].get(), 1)
            XCTAssertEqual(try x[1].get(), 2)
            XCTAssertEqual(try x[2].get(), 3)
            XCTAssertEqual(try x[3].get(), 4)
            XCTAssertEqual(x.count, 4)
            e2.fulfill()
        }
        
        waitForExpectations()
    }

    func testBinaryTuple() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let p1 = Promise.value(1)
        let p2 = Promise.value("abc")
        
        when(fulfilled: p1, p2).done{ v1, v2 in
            XCTAssertEqual(v1, 1)
            XCTAssertEqual(v2, "abc")
            ex.fulfill()
        }.silenceWarning()
        
        when(resolved: p1, p2).done{ r1, r2 in
            XCTAssertEqual(try r1.get(), 1)
            XCTAssertEqual(try r2.get(), "abc")
            ex.fulfill()
        }
        
        waitForExpectations()
    }

    func testTernaryTuple() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let p1 = Promise.value(1)
        let p2 = Promise.value("abc")
        let p3 = Promise.value(1.0)
        
        when(fulfilled: p1, p2, p3).done { v1, v2, v3 in
            XCTAssertEqual(v1, 1)
            XCTAssertEqual(v2, "abc")
            XCTAssertEqual(v3, 1.0)
            ex.fulfill()
        }.silenceWarning()
        
        when(resolved: p1, p2, p3).done { r1, r2, r3 in
            XCTAssertEqual(try r1.get(), 1)
            XCTAssertEqual(try r2.get(), "abc")
            XCTAssertEqual(try r3.get(), 1.0)
            ex.fulfill()
        }
        
        waitForExpectations()
    }

    func testQuaternaryTuple() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let p1 = Promise.value(1)
        let p2 = Promise.value("abc")
        let p3 = Promise.value(1.0)
        let p4 = Promise.value(true)
        
        when(fulfilled: p1, p2, p3, p4).done { v1, v2, v3, v4 in
            XCTAssertEqual(v1, 1)
            XCTAssertEqual(v2, "abc")
            XCTAssertEqual(v3, 1.0)
            XCTAssertEqual(v4, true)
            ex.fulfill()
        }.silenceWarning()
        
        when(resolved: p1, p2, p3, p4).done { r1, r2, r3, r4 in
            XCTAssertEqual(try r1.get(), 1)
            XCTAssertEqual(try r2.get(), "abc")
            XCTAssertEqual(try r3.get(), 1.0)
            XCTAssertEqual(try r4.get(), true)
            ex.fulfill()
        }
        
        waitForExpectations()
    }

    func testQuinaryTuple() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let p1 = Promise.value(1)
        let p2 = Promise.value("abc")
        let p3 = Promise.value(1.0)
        let p4 = Promise.value(true)
        let p5 = Promise.value("a" as Character)
        
        when(fulfilled: p1, p2, p3, p4, p5).done { v1, v2, v3, v4, v5 in
            XCTAssertEqual(v1, 1)
            XCTAssertEqual(v2, "abc")
            XCTAssertEqual(v3, 1.0)
            XCTAssertEqual(v4, true)
            XCTAssertEqual(v5, "a" as Character)
            ex.fulfill()
        }.silenceWarning()
        
        when(resolved: p1, p2, p3, p4, p5).done { r1, r2, r3, r4, r5 in
            XCTAssertEqual(try r1.get(), 1)
            XCTAssertEqual(try r2.get(), "abc")
            XCTAssertEqual(try r3.get(), 1.0)
            XCTAssertEqual(try r4.get(), true)
            XCTAssertEqual(try r5.get(), "a" as Character)
            ex.fulfill()
        }
        
        waitForExpectations()
    }
    
    func testSenaryTuple() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let p1 = Promise.value(1)
        let p2 = Promise.value("abc")
        let p3 = Promise.value(1.0)
        let p4 = Promise.value(true)
        let p5 = Promise.value("a" as Character)
        let p6 = Promise.value(CGFloat(6))
        
        when(fulfilled: p1, p2, p3, p4, p5, p6).done { v1, v2, v3, v4, v5, v6 in
            XCTAssertEqual(v1, 1)
            XCTAssertEqual(v2, "abc")
            XCTAssertEqual(v3, 1.0)
            XCTAssertEqual(v4, true)
            XCTAssertEqual(v5, "a" as Character)
            XCTAssertEqual(v6, CGFloat(6))
            ex.fulfill()
        }.silenceWarning()
        
        when(resolved: p1, p2, p3, p4, p5, p6).done { r1, r2, r3, r4, r5, r6 in
            XCTAssertEqual(try r1.get(), 1)
            XCTAssertEqual(try r2.get(), "abc")
            XCTAssertEqual(try r3.get(), 1.0)
            XCTAssertEqual(try r4.get(), true)
            XCTAssertEqual(try r5.get(), "a" as Character)
            XCTAssertEqual(try r6.get(), CGFloat(6))
            ex.fulfill()
        }
        
        waitForExpectations()
    }

    func testSeptenaryTuple() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let p1 = Promise.value(1)
        let p2 = Promise.value("abc")
        let p3 = Promise.value(1.0)
        let p4 = Promise.value(true)
        let p5 = Promise.value("a" as Character)
        let p6 = Promise.value(CGFloat(6))
        let p7 = Promise.value(1 as Int?)
        
        when(fulfilled: p1, p2, p3, p4, p5, p6, p7).done { v1, v2, v3, v4, v5, v6, v7 in
            XCTAssertEqual(v1, 1)
            XCTAssertEqual(v2, "abc")
            XCTAssertEqual(v3, 1.0)
            XCTAssertEqual(v4, true)
            XCTAssertEqual(v5, "a" as Character)
            XCTAssertEqual(v6, CGFloat(6))
            XCTAssertEqual(v7, 1 as Int?)
            ex.fulfill()
        }.silenceWarning()
        
        when(resolved: p1, p2, p3, p4, p5, p6, p7).done { r1, r2, r3, r4, r5, r6, r7 in
            XCTAssertEqual(try r1.get(), 1)
            XCTAssertEqual(try r2.get(), "abc")
            XCTAssertEqual(try r3.get(), 1.0)
            XCTAssertEqual(try r4.get(), true)
            XCTAssertEqual(try r5.get(), "a" as Character)
            XCTAssertEqual(try r6.get(), CGFloat(6))
            XCTAssertEqual(try r7.get(), 1 as Int?)
            ex.fulfill()
        }
        
        waitForExpectations()
    }
    
    func testOctonaryTuple() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let p1 = Promise.value(1)
        let p2 = Promise.value("abc")
        let p3 = Promise.value(1.0)
        let p4 = Promise.value(true)
        let p5 = Promise.value("a" as Character)
        let p6 = Promise.value(CGFloat(6))
        let p7 = Promise.value(1 as Int?)
        let p8 = Promise.value("abc" as String?)
        
        when(fulfilled: p1, p2, p3, p4, p5, p6, p7, p8).done { v1, v2, v3, v4, v5, v6, v7, v8 in
            XCTAssertEqual(v1, 1)
            XCTAssertEqual(v2, "abc")
            XCTAssertEqual(v3, 1.0)
            XCTAssertEqual(v4, true)
            XCTAssertEqual(v5, "a" as Character)
            XCTAssertEqual(v6, CGFloat(6))
            XCTAssertEqual(v7, 1 as Int?)
            XCTAssertEqual(v8, "abc" as String?)
            ex.fulfill()
        }.silenceWarning()
        
        when(resolved: p1, p2, p3, p4, p5, p6, p7, p8).done { r1, r2, r3, r4, r5, r6, r7, r8 in
            XCTAssertEqual(try r1.get(), 1)
            XCTAssertEqual(try r2.get(), "abc")
            XCTAssertEqual(try r3.get(), 1.0)
            XCTAssertEqual(try r4.get(), true)
            XCTAssertEqual(try r5.get(), "a" as Character)
            XCTAssertEqual(try r6.get(), CGFloat(6))
            XCTAssertEqual(try r7.get(), 1 as Int?)
            XCTAssertEqual(try r8.get(), "abc" as String?)
            ex.fulfill()
        }
        
        waitForExpectations()
    }
    
    func testNovenaryTuple() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let p1 = Promise.value(1)
        let p2 = Promise.value("abc")
        let p3 = Promise.value(1.0)
        let p4 = Promise.value(true)
        let p5 = Promise.value("a" as Character)
        let p6 = Promise.value(CGFloat(6))
        let p7 = Promise.value(1 as Int?)
        let p8 = Promise.value("abc" as String?)
        let p9 = Promise.value(nil as Double?)
        
        when(fulfilled: p1, p2, p3, p4, p5, p6, p7, p8, p9).done { v1, v2, v3, v4, v5, v6, v7, v8, v9 in
            XCTAssertEqual(v1, 1)
            XCTAssertEqual(v2, "abc")
            XCTAssertEqual(v3, 1.0)
            XCTAssertEqual(v4, true)
            XCTAssertEqual(v5, "a" as Character)
            XCTAssertEqual(v6, CGFloat(6))
            XCTAssertEqual(v7, 1 as Int?)
            XCTAssertEqual(v8, "abc" as String?)
            XCTAssertEqual(v9, nil)
            ex.fulfill()
        }.silenceWarning()
        
        when(resolved: p1, p2, p3, p4, p5, p6, p7, p8, p9).done { r1, r2, r3, r4, r5, r6, r7, r8, r9 in
            XCTAssertEqual(try r1.get(), 1)
            XCTAssertEqual(try r2.get(), "abc")
            XCTAssertEqual(try r3.get(), 1.0)
            XCTAssertEqual(try r4.get(), true)
            XCTAssertEqual(try r5.get(), "a" as Character)
            XCTAssertEqual(try r6.get(), CGFloat(6))
            XCTAssertEqual(try r7.get(), 1 as Int?)
            XCTAssertEqual(try r8.get(), "abc" as String?)
            XCTAssertEqual(try r9.get(), nil)
            ex.fulfill()
        }
        
        waitForExpectations()
    }
    
    func testVoid() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let p1 = Promise.value(1).done { _ in }
        let p2 = Promise.value(2).done { _ in }
        let p3 = Promise.value(3).done { _ in }
        let p4 = Promise.value(4).done { _ in }

        when(fulfilled: p1, p2, p3, p4).done { _ in ex.fulfill() }.silenceWarning()
        when(resolved: p1, p2, p3, p4).done { _ in ex.fulfill() }
        waitForExpectations()
    }
    
    func testRejected() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let p1 = after(.milliseconds(100)).map{ true }
        let p2: Promise<Bool> = after(.milliseconds(200)).map{ throw TestError.dummy }
        let p3 = Promise.value(false)
            
        when(fulfilled: p1, p2, p3).catch { _ in
            ex.fulfill()
        }
        when(resolved: p1, p2, p3).done { _, r2, _ in
            XCTAssertEqual(r2.error! as! TestError, TestError.dummy)
            ex.fulfill()
        }
        
        waitForExpectations()
    }

    func testProgress() {
        let ex = expectation(description: "")

        XCTAssertNil(Progress.current())

        let p1 = after(.milliseconds(10))
        let p2 = after(.milliseconds(20))
        let p3 = after(.milliseconds(30))
        let p4 = after(.milliseconds(40))

        let progress = Progress(totalUnitCount: 1)
        progress.becomeCurrent(withPendingUnitCount: 1)

        when(fulfilled: p1, p2, p3, p4).done { _ in
            XCTAssertEqual(progress.completedUnitCount, 1)
            ex.fulfill()
        }.silenceWarning()

        progress.resignCurrent()
        
        waitForExpectations()
    }

    func testProgressDoesNotExceed100Percent() {
        let ex1 = expectation(description: "")
        let ex2 = expectation(description: "")

        XCTAssertNil(Progress.current())

        let p1 = after(.milliseconds(10))
        let p2 = after(.milliseconds(20)).done { throw NSError(domain: "a", code: 1, userInfo: nil) }
        let p3 = after(.milliseconds(30))
        let p4 = after(.milliseconds(40))

        let progress = Progress(totalUnitCount: 1)
        progress.becomeCurrent(withPendingUnitCount: 1)

        let promise = when(fulfilled: p1, p2, p3, p4)

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
        p1.done(on: q, finally)
        p2.ensure(on: q, finally).silenceWarning()
        p3.done(on: q, finally)
        p4.done(on: q, finally)

        waitForExpectations()
    }

    func testUnhandledErrorHandlerDoesNotFire() {
        let ex = expectation(description: "")
        let p1 = Promise<Void>(error: TestError.dummy)
        let p2 = after(.milliseconds(100))
        when(fulfilled: p1, p2).done{ _ in XCTFail() }.catch { error in
            XCTAssertTrue(error as? TestError == TestError.dummy)
            ex.fulfill()
        }

        waitForExpectations()
    }

    func testUnhandledErrorHandlerDoesNotFireForStragglers() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 3

        let p1 = Promise<Void>(error: TestError.dummy)
        let p2 = after(.milliseconds(100)).done { throw TestError.straggler }
        let p3 = after(.milliseconds(200)).done { throw TestError.straggler }

        let whenFulfilledP1P2P3: Promise<(Void, Void, Void)> = when(fulfilled: p1, p2, p3)
        whenFulfilledP1P2P3.catch { error -> Void in
            XCTAssertTrue(TestError.dummy == error as? TestError)
            ex.fulfill()
        }

        p2.ensure { after(.milliseconds(100)).done(ex.fulfill) }.silenceWarning()
        p3.ensure { after(.milliseconds(100)).done(ex.fulfill) }.silenceWarning()

        waitForExpectations()
    }

    func testAllSealedRejectedFirstOneRejects() {
        let ex = expectation(description: "")
        let p1 = Promise<Void>(error: TestError.dummy)
        let p2 = Promise<Void>(error: TestError.straggler)
        let p3 = Promise<Void>(error: TestError.stub)

        when(fulfilled: p1, p2, p3).catch { error in
            XCTAssertTrue(error as? TestError == TestError.dummy)
            ex.fulfill()
        }

        waitForExpectations()
    }

    func testGuaranteeWhen() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2

        when(resolved: Guarantee(), Guarantee()).done { _ in
            ex.fulfill()
        }

        when(resolved: [Guarantee(), Guarantee()]).done {
            ex.fulfill()
        }

        waitForExpectations()
    }
    
    func testMixedThenables() {
        let ex = expectation(description: "")
        ex.expectedFulfillmentCount = 2
        let p1 = Promise.value(true)
        let p2 = Promise.value(2)
        let g1 = Guarantee.value("abc")
        
        when(fulfilled: p1, p2, g1).done { v1, v2, v3 in
            XCTAssertEqual(v1, true)
            XCTAssertEqual(v2, 2)
            XCTAssertEqual(v3, "abc")
            ex.fulfill()
        }.silenceWarning()
        
        when(resolved: p1, p2, g1).done { r1, r2, r3 in
            XCTAssertEqual(try r1.get(), true)
            XCTAssertEqual(try r2.get(), 2)
            XCTAssertEqual(r3, "abc")
            ex.fulfill()
        }.silenceWarning()
        
        waitForExpectations()
    }
}

private enum TestError: Error {
    case dummy
    case straggler
    case stub
}

private extension XCTestCase {
    
    func waitForExpectations() {
        waitForExpectations(timeout: 5)
    }
}
