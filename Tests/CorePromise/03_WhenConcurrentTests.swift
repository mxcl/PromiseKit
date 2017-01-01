import XCTest
import PromiseKit

class WhenConcurrentTestCase_Swift: XCTestCase {

    func testWhen() {
        let e = expectation(description: "")

        var numbers = (0..<42).makeIterator()
        let squareNumbers = numbers.map { $0 * $0 }

        let generator = AnyIterator<Promise<Int>> {
            guard let number = numbers.next() else {
                return nil
            }

            return after(interval: 0.01).then {
                return number * number
            }
        }

        when(fulfilled: generator, concurrently: 5)
            .then { numbers in
                if numbers == squareNumbers {
                    e.fulfill()
                }
            }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testWhenEmptyGenerator() {
        let e = expectation(description: "")

        let generator = AnyIterator<Promise<Int>> {
            return nil
        }

        when(fulfilled: generator, concurrently: 5)
            .then { numbers in
                if numbers.count == 0 {
                    e.fulfill()
                }
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testWhenGeneratorError() {
        enum LocalError: Error {
            case Unknown
            case DivisionByZero
        }

        let expectedErrorIndex = 42
        let expectedError = LocalError.DivisionByZero

        let e = expectation(description: "")

        var numbers = (-expectedErrorIndex..<expectedErrorIndex).makeIterator()

        let generator = AnyIterator<Promise<Int>> {
            guard let number = numbers.next() else {
                return nil
            }

            return after(interval: 0.01).then { _ -> Promise<Int> in
                guard number != 0 else {
                    return Promise(error: expectedError)
                }
                return Promise(100500 / number)
            }
        }

        when(fulfilled: generator, concurrently: 3)
            .catch { error in
                guard let error = error as? LocalError else {
                    return
                }
                guard case .DivisionByZero = error else {
                    return
                }
                e.fulfill()
            }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testWhenConcurrency() {
        let expectedConcurrently = 4
        var currentConcurrently = 0
        var maxConcurrently = 0

        let e = expectation(description: "")

        var numbers = (0..<42).makeIterator()

        let generator = AnyIterator<Promise<Int>> {
            currentConcurrently += 1
            maxConcurrently = max(maxConcurrently, currentConcurrently)

            guard let number = numbers.next() else {
                return nil
            }

            return after(interval: 0.01).then { _ -> Promise<Int> in
                currentConcurrently -= 1
                return Promise(number * number)
            }
        }

        when(fulfilled: generator, concurrently: expectedConcurrently)
            .then { numbers in
                if expectedConcurrently == maxConcurrently {
                    e.fulfill()
                }
        }

        waitForExpectations(timeout: 3)
    }

    func testWhenConcurrencyLessThanZero() {
        let ex1 = expectation(description: "")
        let ex2 = expectation(description: "")
        let generator = AnyIterator<Promise<Int>> { XCTFail(); return nil }

        let p1 = when(fulfilled: generator, concurrently: 0)
        let p2 = when(fulfilled: generator, concurrently: -1)

        for (p, e) in [(p1, ex1), (p2, ex2)] {
            p.catch { error in
                guard case PMKError.badInput = error else { return XCTFail() }
                e.fulfill()
            }
        }

        waitForExpectations(timeout: 10)
    }

    func testStopsDequeueingOnceRejected() {
        let ex = expectation(description: "")
        enum Error: Swift.Error { case dummy }

        var x: UInt = 0
        let generator = AnyIterator<Promise<Void>> {
            x += 1
            switch x {
            case 0:
                fatalError()
            case 1:
                return Promise()
            case 2:
                return Promise(error: Error.dummy)
            case _:
                XCTFail()
                return nil
            }
        }

        when(fulfilled: generator, concurrently: 1).then {
            XCTFail("\($0)")
        }.catch { error in
            ex.fulfill()
        }

        waitForExpectations(timeout: 3)
    }
}
