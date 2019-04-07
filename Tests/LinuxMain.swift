import XCTest

import A_
import CorePromise

var tests = [XCTestCaseEntry]()
tests += A_.__allTests()
tests += CorePromise.__allTests()

XCTMain(tests)
