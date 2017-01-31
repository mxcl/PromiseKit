import PromiseKit
import XCTest

private enum E: Error {
    case test
}

class WrapTests: XCTestCase {

    func testStandardCompletionHandlerSuccess() {
        struct KittenFetcher {
            func fetch(with body: (Int?, Error?) -> Void) {
                body(3, nil)
            }
        }

        wait { ex in
            Promise { seal in
                KittenFetcher().fetch(with: seal.resolve)
            }.then {
                XCTAssertEqual($0, 3)
                ex.fulfill()
            }
        }
    }

    func testStandardCompletionHandlerFailure() {
        struct KittenFetcher {
            func fetch(with body: (Int?, Error?) -> Void) {
                body(nil, E.test)
            }
        }

        wait { ex in
            Promise { seal in
                KittenFetcher().fetch(with: seal.resolve)
            }.catch { error in
                if case E.test = error { ex.fulfill() }
            }
        }
    }

    func testStandardCompletionHandlerInvalidCallingConvention() {
        struct KittenFetcher {
            func fetch(with body: (Int?, Error?) -> Void) {
                body(nil, nil)
            }
        }

        wait { ex in
            Promise { seal in
                KittenFetcher().fetch(with: seal.resolve)
            }.catch { error in
                if case PMKError.invalidCallingConvention = error { ex.fulfill() }
            }
        }
    }

    func testNonOptionalValueParameterSuccess() {
        struct KittenFetcher {
            func fetch(with body: (Int, Error?) -> Void) {
                body(3, nil)
            }
        }

        wait { ex in
            Promise { seal in
                KittenFetcher().fetch(with: seal.resolve)
            }.then {
                XCTAssertEqual($0, 3)
                ex.fulfill()
            }
        }
    }

    func testNonOptionalValueParameterFailure() {
        struct KittenFetcher {
            func fetch(with body: (Int, Error?) -> Void) {
                body(-1, E.test)
            }
        }

        wait { ex in
            Promise { seal in
                KittenFetcher().fetch(with: seal.resolve)
            }.catch { error in
                if case E.test = error { ex.fulfill() }
            }
        }
    }

    func testInvertedCompletionHandlerSuccess() {
        struct KittenFetcher {
            func fetch(with body: (Error?, Int?) -> Void) {
                body(nil, 3)
            }
        }

        wait { ex in
            Promise { seal in
                KittenFetcher().fetch(with: seal.resolve)
                }.then {
                    XCTAssertEqual($0, 3)
                    ex.fulfill()
            }
        }
    }

    func testInvertedCompletionHandlerFailure() {
        struct KittenFetcher {
            func fetch(with body: (Error?, Int?) -> Void) {
                body(E.test, nil)
            }
        }

        wait { ex in
            Promise { seal in
                KittenFetcher().fetch(with: seal.resolve)
                }.catch { error in
                    if case E.test = error { ex.fulfill() }
            }
        }
    }

    func testInvertedCompletionHandlerInvalidCallingConvention() {
        struct KittenFetcher {
            func fetch(with body: (Error?, Int?) -> Void) {
                body(nil, nil)
            }
        }

        wait { ex in
            Promise { seal in
                KittenFetcher().fetch(with: seal.resolve)
                }.catch { error in
                    if case PMKError.invalidCallingConvention = error { ex.fulfill() }
            }
        }
    }

}
