import PromiseKit
import XCTest

// we reject with this when we don't intend to test against it
enum Error: ErrorProtocol { case dummy }

func later(_ ticks: Int = 1, _ body: () -> Void) {
    let ticks = Double(NSEC_PER_SEC) / (Double(ticks) * 50.0 * 1000.0)
    DispatchQueue.main.after(when: DispatchTime.now() + Double(Int64(ticks)) / Double(NSEC_PER_SEC), execute: body)
}



extension XCTestCase {

    func testFulfilled(_ numberOfExpectations: Int  = 1, body: (Promise<Int>, [XCTestExpectation], Int) -> Void) {

        let specify = mkspecify(numberOfExpectations, generator: { Int(arc4random()) }, body: body)

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

    func testRejected(_ numberOfExpectations: Int = 1, body: (Promise<Int>, [XCTestExpectation], ErrorProtocol) -> Void) {

        let specify = mkspecify(numberOfExpectations, generator: { _ -> ErrorProtocol in
            return NSError(domain: PMKErrorDomain, code: Int(arc4random()), userInfo: nil)
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

    private func mkspecify<T>(_ numberOfExpectations: Int, generator: () -> T, body: (Promise<Int>, [XCTestExpectation], T) -> Void) -> (String, feed: (T) -> (Promise<Int>, () -> Void)) -> Void {
        return { desc, feed in
            let floater = self.expectation(withDescription: "")
			later(2, floater.fulfill)
			
            let value = generator()
            let (promise, after) = feed(value)
            let expectations = (1...numberOfExpectations).map {
                self.expectation(withDescription: "\(desc) (\($0))")
            }
            body(promise, expectations, value)
            
            after()
            
            self.waitForExpectations(withTimeout: 1, handler: nil)
        }
    }
}


func XCTAssertEqual(_ e1: ErrorProtocol, _ e2: ErrorProtocol) {
    XCTAssert(e1 as NSError == e2 as NSError)
}
