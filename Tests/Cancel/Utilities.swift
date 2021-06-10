import PromiseKit
import XCTest

// Workaround for error with missing libswiftContacts.dylib, this import causes the
// library to be included as needed
#if os(iOS) || os(watchOS) || os(OSX)
import class Contacts.CNPostalAddress
#endif

extension Promise {
    func silenceWarning() {}
}

extension CancellablePromise {
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
