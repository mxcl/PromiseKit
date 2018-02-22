import PromiseKit
import XCTest

class AnyPromiseTests: XCTestCase {
    func testFulfilledResult() {
        switch AnyPromise(Promise.value(true)).result {
        case .fulfilled(let obj as Bool)? where obj:
            break
        default:
            XCTFail()
        }
    }

    func testRejectedResult() {
        switch AnyPromise(Promise<Int>(error: PMKError.badInput)).result {
        case .rejected(let err)?:
            print(err)
            break
        default:
            XCTFail()
        }
    }

    func testPendingResult() {
        switch AnyPromise(Promise<Int>.pending().promise).result {
        case nil:
            break
        default:
            XCTFail()
        }
    }

    func testCustomStringConvertible() {
        XCTAssertEqual("\(AnyPromise(Promise<Int>.pending().promise))", "AnyPromise(…)")
        XCTAssertEqual("\(AnyPromise(Promise.value(1)))", "AnyPromise(1)")
        XCTAssertEqual("\(AnyPromise(Promise<Int?>.value(nil)))", "AnyPromise(nil)")
    }
}
