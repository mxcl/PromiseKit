import PromiseKit
import XCTest


class Test2121: XCTestCase {
    // "When fulfilled, a promise: must not transition to any other state."

    func test1() {
        suiteFulfilled(1) { (promise, ee, _)->() in
            var onFulfilledCalled = false
            promise.then { a in
                onFulfilledCalled = true
            }
            promise.catch { e->() in
                XCTAssertFalse(onFulfilledCalled)
                ee[0].fulfill()
            }
            later {
                ee[0].fulfill()
            }
        }
    }

    func test2() {
        var onFulfilledCalled = false
        let (promise, fulfiller, rejecter) = Promise<Int>.defer()
        promise.then{ a -> Void in
            onFulfilledCalled = true
        }
        promise.catch{ e -> Void in
            XCTAssertFalse(onFulfilledCalled)
        }
        fulfiller(dummy)
        rejecter(dammy)
        spin()
    }

    func test3() {
        var onFulfilledCalled = false
        let (promise, fulfiller, rejecter) = Promise<Int>.defer()

        promise.then{ a->() in
            onFulfilledCalled = true;
        }
        promise.catch{ e->() in
            XCTAssertFalse(onFulfilledCalled)
        }

        later {
            fulfiller(dummy)
            rejecter(dammy)
        }
        spin()
    }

    func test4() {
        var onFulfilledCalled = false
        let (promise, fulfiller, rejecter) = Promise<Int>.defer()

        promise.then{ a in
            onFulfilledCalled = true
        }
        promise.catch{ e->() in
            XCTAssertFalse(onFulfilledCalled)
        }

        fulfiller(dummy)
        later {
            rejecter(dammy)
        }
        spin()
    }
}





// we fulfill with this when we don't intend to test against it
let dummy = 123

// we reject with this when we don't intend to test against it
let dammy = NSError(domain: PMKErrorDomain, code: dummy, userInfo: nil)

// a sentinel fulfillment value to test for with strict equality
var sentinel = 456

func later(block: ()->()) {
    later(50, block)
}
func later(timeout: Double, block: ()->()) {
    let ticks = Double(NSEC_PER_SEC) / (timeout * 1000.0)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(ticks)), dispatch_get_main_queue(), block)
}

func spin() {
    NSRunLoop.mainRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 0.1))
}


extension XCTestCase {
    func suiteFulfilled(numberOfExpectations:Int, test:(Promise<Int>, [XCTestExpectation!], Int)->Void) {
        
        func e(desc: String) -> [XCTestExpectation!] {
            return [Int](1...numberOfExpectations).map{ self.expectationWithDescription("\(desc) (\($0))") }
        }
        
        let v1 = Int(rand())
        let e1 = e("already-fulfilled")
        test(Promise(v1), e1, v1)
        waitForExpectationsWithTimeout(1, handler: nil)
        
        let (p2, f2, _) = Promise<Int>.defer()
        let v2 = Int(rand())
        let e2 = e("immediately-fulfilled")
        test(p2, e2, v2)
        f2(v2)
        waitForExpectationsWithTimeout(1, handler: nil)
        
        let (p3, f3, _) = Promise<Int>.defer()
        let v3 = Int(rand())
        let e3 = e("eventually-fulfilled")
        later {
            test(p3, e3, v3)
            f3(v3)
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func suiteRejected(numberOfExpectations:Int, test:(Promise<Int>, [XCTestExpectation!], NSError)->Void) {
        
        func e(desc: String) -> [XCTestExpectation!] {
            return [Int](1...numberOfExpectations).map{ self.expectationWithDescription("\(desc) (\($0))") }
        }
        
        let v1 = NSError(domain:PMKErrorDomain, code:Int(rand()), userInfo:nil)
        let e1 = e("already-fulfilled")
        
        test(Promise(v1), e1, v1)
        waitForExpectationsWithTimeout(1, handler: nil)
        
        let e2 = e("immediately-rejected")
        let (p2, _, r2) = Promise<Int>.defer()
        let v2 = NSError(domain:PMKErrorDomain, code:Int(rand()), userInfo:nil)
        test(p2, e2, v2)
        r2(v2)
        waitForExpectationsWithTimeout(1, handler: nil)
        
        let e3 = e("eventually-rejected")
        let (p3, _, r3) = Promise<Int>.defer()
        let v3 = NSError(domain:PMKErrorDomain, code:Int(rand()), userInfo:nil)
        later {
            test(p3, e3, v3)
            r3(v3)
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
