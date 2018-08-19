import PromiseKit

extension Promise {
    func silenceWarning() {}
}

#if os(Linux) && (swift(>=4.0) && !swift(>=4.1))
typealias LineInt = Int
#else
typealias LineInt = UInt
#endif

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
    func wait(for: [XCTestExpectation], timeout: TimeInterval, file: StaticString = #file, line: LineInt = #line) {
        waitForExpectations(timeout: timeout, file: file, line: Int(line))
    }
}

extension XCTestExpectation {
    func fulfill() {
        fulfill(#file, line: #line)
    }
}
#endif
