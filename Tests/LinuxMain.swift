import XCTest

import APlus
import CorePromise

var tests = [XCTestCaseEntry]()
tests += APlus.__allTests()
tests += CorePromise.__allTests()

XCTMain(tests)
