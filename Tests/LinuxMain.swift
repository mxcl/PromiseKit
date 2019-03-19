import XCTest

import A__js
import A__swift
import Cancel
import Core

var tests = [XCTestCaseEntry]()
tests += A__js.__allTests()
tests += A__swift.__allTests()
tests += Cancel.__allTests()
tests += Core.__allTests()

XCTMain(tests)
