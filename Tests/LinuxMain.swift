import XCTest

import A__js
import A__swift
import Core
import Cancel

var tests = [XCTestCaseEntry]()
tests += A__js.__allTests()
tests += A__swift.__allTests()
tests += Core.__allTests()
tests += Cancel.__allTests()

XCTMain(tests)
