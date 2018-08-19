import PromiseKit

extension Promise {
    func silenceWarning() {}
}

#if os(Linux)
import func CoreFoundation._CFIsMainThread

extension Thread {
    // `isMainThread` is not implemented yet in swift-corelibs-foundation.
    static var isMainThread: Bool {
        return _CFIsMainThread()
    }
}

import XCTest

extension XCTestCase {
    func wait(for: [XCTestExpectation], timeout: TimeInterval, file: StaticString = #file, line: UInt = #line) {
    #if !(swift(>=4.0) && !swift(>=4.1))
        let line = Int(line)
    #endif
        waitForExpectations(timeout: timeout, file: file, line: line)
    }
}

extension XCTestExpectation {
    func fulfill() {
        fulfill(#file, line: #line)
    }
}
#endif
