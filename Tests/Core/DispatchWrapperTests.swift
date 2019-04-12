import Dispatch
import PromiseKit
import XCTest

// Exercise the whole API through DispatchQueue wrappers. The test here is really
// that everything compiles smoothly, not anything that happens at test time.

class DispatchWrapperTests: XCTestCase {
    
    enum TestError: Error, Equatable {
        case errorOne
        case errorTwo
        case errorThree
        case errorFour
        case errorFive
        case errorSix
        case errorSeven
        case errorEight
    }
    
    enum OtherError: Error, Equatable {
        case errorOne
    }

    func testWrappedPromiseThenableAPI() {
        let ex = expectation(description: "DispatchQueue Promise API")
        Promise.value(42).then(on: .global()) {
            Promise.value($0 + 10)
        }.map(on: .global()) {
            $0 + 10
        }.get(on: .global()) {
            XCTAssert($0 == 62)
        }.tap(on: .global()) { result in
            if case let .success(x) = result {
                XCTAssert(x == 62)
            } else {
                XCTFail()
            }
        }.compactMap(on: .global()) {
            $0 + 10
        }.done(on: .global()) {
            XCTAssert($0 == 72)
            ex.fulfill()
        }.catch(on: .global()) { _ in
            XCTFail()
        }
        waitForExpectations(timeout: 1)
    }
    
    func testWrappedPromiseRecoverAPI() {
        
        let ex = expectation(description: "DispatchQueue Promise recover API")
        var value = 0
        Promise.value(42).then { _ -> Promise<Int> in
            throw TestError.errorOne
        // Specific error
        }.recover(only: TestError.errorOne, on: .global()) { error -> Promise<Int> in
            value += 1
            throw TestError.errorTwo
        // Error type
        }.recover(only: TestError.self, on: .global()) { error -> Promise<Int> in
            XCTAssert(error == .errorTwo)
            value += 10
            throw TestError.errorThree
        // Any error
        }.recover(on: .global()) { error -> Promise<Int> in
            if let error = error as? TestError {
                XCTAssert(error == TestError.errorThree)
            } else {
                XCTFail()
            }
            value += 100
            throw TestError.errorFour
        }.map(on: .global()) { _ -> Void in
            // NOP
        // Non-matching specific error
        }.recover(only: TestError.errorThree, on: .global()) { error in
            XCTFail()
        // Specific error, void return
        }.recover(only: TestError.errorFour, on: .global()) { error -> Void in
            value += 1_000
            throw OtherError.errorOne
        // Non-matching error class, void return
        }.recover(only: TestError.self, on: .global()) { error -> Void in
            XCTFail()
        }.recover(only: OtherError.self, on: .global()) { error in
            value += 10_000
            throw TestError.errorFive
        }.ensure(on: .global()) {
            value += 100_000
        }.catch { error in
            if let error = error as? TestError {
                XCTAssert(error == TestError.errorFive)
            } else {
                XCTFail()
            }
            value += 1_000_000
            ex.fulfill()
        }
        waitForExpectations(timeout: 1)
        XCTAssert(value == 1_111_111)
        
        let g: Any = Promise.value(42).recover(on: .global()) { error in
            Guarantee.value(52)
        }
        XCTAssert(g is Guarantee<Int>)
        
        let g2: Any = Promise.value(()).recover(on: .global()) { error -> Void in }
        XCTAssert(g2 is Guarantee<Void>)
    }

    func testWrappedPromiseCatchAPI() {
        let ex = expectation(description: "DispatchQueue Promise catch API")
        Promise.value(42).then(on: .global()) { _ -> Promise<Int> in
            throw TestError.errorOne
        }.catch(only: OtherError.self, on: .global()) { error in
            XCTFail()
        }.catch(only: TestError.errorTwo, on: .global()) { error in
            XCTFail()
        }.catch(only: TestError.self, on: .global()) { error in
            XCTAssert(error == .errorOne)
            ex.fulfill()
        }.cauterize()
        waitForExpectations(timeout: 1)
    }

    func testWrappedPromiseEnsureAPI() {
        let ex = expectation(description: "DispatchQueue Promise ensure API")
        var value = 0
        Promise.value(42).ensure(on: .global()) {
            value += 1
        }.ensureThen(on: .global()) { () -> Guarantee<Void> in
            value += 10
            return Guarantee<Void>()
        }.done(on: .global()) { _ in
            value += 100
            ex.fulfill()
        }.cauterize()
        waitForExpectations(timeout: 1)
        XCTAssert(value == 111)
    }
    
    func testWrappedPromiseSequenceAPI() {
        let ex = expectation(description: "DispatchQueue Promise sequence API")
        Promise.value([42, 52]).mapValues(on: .global()) {
            $0 + 10
        }.flatMapValues(on: .global()) {
            [$0]
        }.compactMapValues(on: .global()) {
            $0
        }.thenMap(on: .global()) {
            Promise.value($0)
        }.thenFlatMap(on: .global()) {
            Promise.value([$0])
        }.filterValues(on: .global()) {
            $0 > 10
        }.firstValue(on: .global()) {
            $0 > 60
        }.map(on: .global()) { v -> [Int] in
            XCTAssert(v == 62)
            return [82, 72]
        }.sortedValues(on: .global()).done { v in
            XCTAssert(v == [72, 82])
            ex.fulfill()
        }.cauterize()
        waitForExpectations(timeout: 1)
    }

    func testWrappedGuaranteeAPI() {
        let ex = expectation(description: "DispatchQueue Guarantee API")
        Guarantee.value(42).then(on: .global()) {
            Guarantee.value($0 + 10)
        }.map(on: .global()) {
            $0 + 10
        }.get(on: .global()) {
            XCTAssert($0 == 62)
        }.map {
            [$0, $0]
        }.thenMap(on: .global()) {
            Guarantee.value($0 + 10)
        }.done(on: .global()) {
            XCTAssert($0 == [72, 72])
            ex.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
}
