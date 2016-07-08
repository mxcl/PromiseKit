import PromiseKit
import XCTest

// we reject with this when we don't intend to test against it
enum Error: ErrorType { case Dummy }

func later(ticks: Int = 1, _ body: () -> Void) {
    let ticks = Double(NSEC_PER_SEC) / (Double(ticks) * 50.0 * 1000.0)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(ticks)), dispatch_get_main_queue(), body)
}



extension XCTestCase {

    func testFulfilled(numberOfExpectations: Int  = 1, body: (Promise<Int>, [XCTestExpectation], Int) -> Void) {

        let specify = mkspecify(numberOfExpectations, generator: { Int(rand()) }, body: body)

        specify("already-fulfilled") { value in
            return (Promise(value), {})
        }
        specify("immediately-fulfilled") { value in
            let (promise, fulfill, _) = Promise<Int>.pendingPromise()
            return (promise, {
                fulfill(value)
            })
        }
        specify("eventually-fulfilled") { value in
            let (promise, fulfill, _) = Promise<Int>.pendingPromise()
            return (promise, {
                later {
                    fulfill(value)
                }
            })
        }
    }

    func testRejected(numberOfExpectations: Int = 1, body: (Promise<Int>, [XCTestExpectation], ErrorType) -> Void) {

        let specify = mkspecify(numberOfExpectations, generator: { _ -> ErrorType in
            return NSError(domain: PMKErrorDomain, code: Int(rand()), userInfo: nil)
        }, body: body)

        specify("already-rejected") { error in
            return (Promise(error: error), {})
        }
        specify("immediately-rejected") { error in
            let (promise, _, reject) = Promise<Int>.pendingPromise()
            return (promise, {
                reject(error)
            })
        }
        specify("eventually-rejected") { error in
            let (promise, _, reject) = Promise<Int>.pendingPromise()
            return (promise, {
                later {
                    reject(error)
                }
            })
        }
    }


/////////////////////////////////////////////////////////////////////////

    private func mkspecify<T>(numberOfExpectations: Int, generator: () -> T, body: (Promise<Int>, [XCTestExpectation], T) -> Void) -> (String, feed: (T) -> (Promise<Int>, () -> Void)) -> Void {
        return { desc, feed in
            let floater = self.expectationWithDescription("")
			later(2, floater.fulfill)
			
            let value = generator()
            let (promise, after) = feed(value)
            let expectations = (1...numberOfExpectations).map {
                self.expectationWithDescription("\(desc) (\($0))")
            }
            body(promise, expectations, value)
            
            after()
            
            self.waitForExpectationsWithTimeout(1, handler: nil)
        }
    }
}


func XCTAssertEqual(e1: ErrorType, _ e2: ErrorType) {
    XCTAssert(e1 as NSError == e2 as NSError)
}
