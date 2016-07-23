import XCTest
import PromiseKit

class PromiseQueueTestCase_Swift: XCTestCase {

    func testDefaultParameters() {
        let queue = PromiseQueue<Void>()

        XCTAssert(queue.maxPendingPromises == 1, "Default value of `maxPendingPromises` is `1`.")
        XCTAssert(queue.maxQueuedPromises == Int.max, "Default value of `maxQueuedPromises` is `Int.max`.")
    }

    func testMaxQueuedPromises() {
        let e = expectationWithDescription("")
        let queue = PromiseQueue<Void>(maxPendingPromises: 1, maxQueuedPromises: 3)

        let generator = { () -> Promise<Void> in
            return after(0.5)
        }

        queue.add(generator) // Will start immediatly.
        queue.add(generator) // Will add to the queue. (1st)
        queue.add(generator) // Will add to the queue. (2nd)
        queue.add(generator) // Will add to the queue. (3rd)
        queue.add(generator) // Will be rejected with error.
            .error { error in
                if case Error.QueueIsFull =  error {
                    e.fulfill()
                }
            }

        waitForExpectationsWithTimeout(4, handler: nil)
    }

    func testMaxPendingPromises() {
        let e = expectationWithDescription("")
        let maxPendingPromises = 4
        let queue = PromiseQueue<Void>(maxPendingPromises: maxPendingPromises)

        var resourceCounter = 0
        var maxResourceCounter = 0

        let generator = { () -> Promise<Void> in
            resourceCounter += 1
            maxResourceCounter = max(maxResourceCounter, resourceCounter)
            return after(0.1).then {
                resourceCounter -= 1
            }
        }

        for _ in 0..<42 {
            queue.add(generator)
        }

        queue.add(generator)
            .then { () -> Void in
                if maxPendingPromises == maxResourceCounter {
                    e.fulfill()
                }
            }

        waitForExpectationsWithTimeout(4, handler: nil)
    }

    func testFIFO() {
        let e = expectationWithDescription("")
        let queue = PromiseQueue<Int>()

        let metagenerator = { (number: Int) -> (() -> Promise<Int>) in
            return {
                return after(0.01).then {
                    number * number
                }
            }
        }

        var squareNumbers: [Int] = []

        for number in 0..<42 {
            queue.add(metagenerator(number)).then { squareNumbers.append($0) }
        }

        queue.add({ Promise(42) })
            .then { (_) -> Void in
                if squareNumbers.sort() == squareNumbers {
                    e.fulfill()
                }
            }

        waitForExpectationsWithTimeout(4, handler: nil)
    }

    func testFulfill() {
        let e = expectationWithDescription("")

        let result = 42

        let queue = PromiseQueue<Int>()

        let generator = { () -> Promise<Int> in
            return after(0.5).then {
                return result
            }
        }

        queue.add(generator).then { value -> Void in
            if value == result {
                e.fulfill()
            }
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testReject() {
        let e = expectationWithDescription("")

        let expectedError = NSError(domain: "PromiseKitTests", code: 1, userInfo: nil)

        let queue = PromiseQueue<Int>()

        let generator = { () -> Promise<Int> in
            return after(0.5).then {
                return Promise(error: expectedError)
            }
        }

        queue.add(generator).error { error in
            if error as NSError == expectedError {
                e.fulfill()
            }
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testWhen() {
        let e = expectationWithDescription("")

        let numbers = Array(0..<42)
        let squareNumbers = numbers.map { $0 * $0 }

        let generator = { (number: Int) -> Promise<Int> in
            return after(0.01).then {
                return number * number
            }
        }

        when(numbers, generator: generator)
            .then { numbers -> Void in
                if numbers == squareNumbers {
                    e.fulfill()
                }
            }

        waitForExpectationsWithTimeout(1, handler: nil)
    }

}