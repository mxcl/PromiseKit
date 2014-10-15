import PromiseKit
import XCTest

// we fulfill with this when we don't intend to test against it
let dummy = 123

// we reject with this when we don't intend to test against it
let dammy = NSError(domain: PMKErrorDomain, code: dummy, userInfo: nil)

// a sentinel fulfillment value to test for with strict equality
var sentinel = 456

func later(block: ()->()) {
    later(50, block)
}
func later(timeout:Double, block: ()->()) {
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
        test(Promise(value:v1), e1, v1)
        waitForExpectationsWithTimeout(1, handler: nil)

        let d2 = Promise<Int>.defer()
        let v2 = Int(rand())
        let e2 = e("immediately-fulfilled")
        test(d2.promise, e2, v2)
        d2.fulfill(v2)
        waitForExpectationsWithTimeout(1, handler: nil)

        let d3 = Promise<Int>.defer()
        let v3 = Int(rand())
        let e3 = e("eventually-fulfilled")
        later {
            test(d3.promise, e3, v3)
            d3.fulfill(v3)
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func suiteRejected(numberOfExpectations:Int, test:(Promise<Int>, [XCTestExpectation!], NSError)->Void) {

        func e(desc: String) -> [XCTestExpectation!] {
            return [Int](1...numberOfExpectations).map{ self.expectationWithDescription("\(desc) (\($0))") }
        }

        let v1 = NSError(domain:PMKErrorDomain, code:Int(rand()), userInfo:nil)
        let e1 = e("already-fulfilled")

        test(Promise(error:v1), e1, v1)
        waitForExpectationsWithTimeout(1, handler: nil)

        let e2 = e("immediately-rejected")
        let d2 = Promise<Int>.defer()
        let v2 = NSError(domain:PMKErrorDomain, code:Int(rand()), userInfo:nil)
        test(d2.promise, e2, v2)
        d2.reject(v2)
        waitForExpectationsWithTimeout(1, handler: nil)

        let e3 = e("eventually-rejected")
        let d3 = Promise<Int>.defer()
        let v3 = NSError(domain:PMKErrorDomain, code:Int(rand()), userInfo:nil)
        later {
            test(d3.promise, e3, v3)
            d3.reject(v3)
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
