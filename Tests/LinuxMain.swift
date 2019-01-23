import XCTest

import CorePromise
import A_

var tests = [XCTestCaseEntry]()
tests += CorePromise.__allTests()
tests += A_.__allTests()

XCTMain(tests)
