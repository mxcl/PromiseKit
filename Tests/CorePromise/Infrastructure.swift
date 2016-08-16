import PromiseKit
import XCTest

var InjectedErrorUnhandler: (Error) -> Void = { _ in XCTFail() }

@objc(PMKInjected) class Injected: NSObject {
    @objc class func setErrorUnhandler(_ newErrorUnhandler: @escaping (NSError) -> Void) {
        InjectedErrorUnhandler = { newErrorUnhandler($0 as NSError) }
    }

    @objc class func setUp() {
        PMKSetUnhandledErrorHandler { err in
            InjectedErrorUnhandler(err)
        }
    }
}
