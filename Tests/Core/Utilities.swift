import PromiseKit
import XCTest

extension Promise {
    func silenceWarning() {}
}

extension PMKCascadingFinalizer {
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

extension XCTestCase {
    func wait(for: [XCTestExpectation], timeout: TimeInterval, file: StaticString = #file, line: UInt = #line) {
        waitForExpectations(timeout: timeout, file: file, line: Int(line))
    }
}

#endif

#if os(Linux) || os(Windows)
extension XCTestExpectation {
    func fulfill() {
        fulfill(#file, line: #line)
    }
}
#endif

#if os(Windows)
import class Foundation.Thread

func usleep(_ us: UInt32) {
    Thread.sleep(forTimeInterval: Double(us) / 1_000_000.0)
}
#endif
