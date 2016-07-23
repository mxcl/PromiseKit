import XCTest
import PromiseKit

class WhenConcurrentTestCase_Swift: XCTestCase {

    func testWhen() {
        let e = expectationWithDescription("")

        var numbers = (0..<42).generate()
        let squareNumbers = numbers.map { $0 * $0 }

        let generator = AnyGenerator<Promise<Int>> {
            guard let number = numbers.next() else {
                return nil
            }

            return after(0.01).then {
                return number * number
            }
        }

        when(generator, concurrently: 5)
            .then { numbers -> Void in
                if numbers == squareNumbers {
                    e.fulfill()
                }
            }

        waitForExpectationsWithTimeout(3, handler: nil)
    }

    func testWhenEmptyGenerator() {
        let e = expectationWithDescription("")

        let generator = AnyGenerator<Promise<Int>> {
            return nil
        }

        when(generator, concurrently: 5)
            .then { numbers -> Void in
                if numbers.count == 0 {
                    e.fulfill()
                }
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testWhenGeneratorError() {
        enum LocalError: ErrorType {
            case Unknown
            case DivisionByZero
        }

        let expectedErrorIndex = 42
        let expectedError = LocalError.DivisionByZero

        let e = expectationWithDescription("")

        var numbers = (-expectedErrorIndex..<expectedErrorIndex).generate()

        let generator = AnyGenerator<Promise<Int>> {
            guard let number = numbers.next() else {
                return nil
            }

            return after(0.01).then {
                guard number != 0 else {
                    return Promise(error: expectedError)
                }

                return Promise(100500 / number)
            }
        }

        when(generator, concurrently: 3)
            .error { error in
                guard let error = error as? Error else {
                    return
                }

                guard case .When(let errorIndex, let internalError) = error else {
                    return
                }

                guard let localInternalError = internalError as? LocalError else {
                    return
                }

                guard errorIndex == expectedErrorIndex && localInternalError == expectedError else {
                    return
                }

                e.fulfill()
            }

        waitForExpectationsWithTimeout(3, handler: nil)
    }

    func testWhenConcurrency() {
        let expectedConcurrently = 4
        var currentConcurrently = 0
        var maxConcurrently = 0

        let e = expectationWithDescription("")

        var numbers = (0..<42).generate()

        let generator = AnyGenerator<Promise<Int>> {
            currentConcurrently += 1
            maxConcurrently = max(maxConcurrently, currentConcurrently)

            guard let number = numbers.next() else {
                return nil
            }

            return after(0.01).then {
                currentConcurrently -= 1
                return Promise(number * number)
            }
        }

        when(generator, concurrently: expectedConcurrently)
            .then { numbers -> Void in
                if expectedConcurrently == maxConcurrently {
                    e.fulfill()
                }
        }

        waitForExpectationsWithTimeout(3, handler: nil)
    }

    func testWhenConcurrencyLessThanZero() {
        let generator = AnyGenerator<Promise<Int>> { XCTFail(); return nil }

        let p1 = when(generator, concurrently: 0)
        let p2 = when(generator, concurrently: -1)

        guard let e1 = p1.error else { return XCTFail() }
        guard let e2 = p2.error else { return XCTFail() }
        guard case Error.WhenConcurrentlyZero = e1 else { return XCTFail() }
        guard case Error.WhenConcurrentlyZero = e2 else { return XCTFail() }
    }
}
