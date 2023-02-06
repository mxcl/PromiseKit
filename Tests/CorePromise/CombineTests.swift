#if canImport(Combine)
import Combine
import PromiseKit
import XCTest

private enum Error: Swift.Error { case dummy }

class CombineTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    
    override func setUp() {
        cancellables = []
    }
    
    func testCombinePromiseValue() {
        let ex = expectation(description: "")
        let promise = after(.milliseconds(100)).then(on: nil){ Promise.value(1) }
        promise.future().sink { result in
            switch result {
            case .failure:
                XCTAssert(false)
            default:
                XCTAssert(true)
            }
        } receiveValue: {
            XCTAssertEqual($0, 1)
            ex.fulfill()
        }.store(in: &cancellables)

        wait(for: [ex], timeout: 1)
    }
    
    func testCombineGuaranteeValue() {
        let ex = expectation(description: "")
        let promise = after(.milliseconds(100)).then(on: nil){ Guarantee.value(1) }
        promise.future().sink { result in
            switch result {
            case .failure:
                XCTAssert(false)
            default:
                XCTAssert(true)
            }
        } receiveValue: {
            XCTAssertEqual($0, 1)
            ex.fulfill()
        }.store(in: &cancellables)

        wait(for: [ex], timeout: 1)
    }
    
    func testCombinePromiseThrow() {
        let ex = expectation(description: "")
        let promise = after(.milliseconds(100)).then(on: nil){ Promise(error: Error.dummy) }.then(on: nil){ Promise.value(1) }
        promise.future().sink { result in
            switch result {
            case .failure(let error):
                switch error as? Error {
                case .dummy:
                    XCTAssert(true)
                default:
                    XCTAssert(false)
                }
            default:
                XCTAssert(false)
            }
        } receiveValue: { _ in
            XCTAssert(false)
        }.store(in: &cancellables)

        wait(for: [ex], timeout: 1)
    }
}
#endif
