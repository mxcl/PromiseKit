import XCTest

extension Test212 {
    static let __allTests = [
        ("test", test),
    ]
}

extension Test213 {
    static let __allTests = [
        ("test", test),
    ]
}

extension Test222 {
    static let __allTests = [
        ("test", test),
    ]
}

extension Test223 {
    static let __allTests = [
        ("test", test),
    ]
}

extension Test224 {
    static let __allTests = [
        ("test", test),
    ]
}

extension Test226 {
    static let __allTests = [
        ("test", test),
    ]
}

extension Test227 {
    static let __allTests = [
        ("test", test),
    ]
}

extension Test231 {
    static let __allTests = [
        ("test", test),
    ]
}

extension Test232 {
    static let __allTests = [
        ("test", test),
    ]
}

extension Test234 {
    static let __allTests = [
        ("test", test),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(Test212.__allTests),
        testCase(Test213.__allTests),
        testCase(Test222.__allTests),
        testCase(Test223.__allTests),
        testCase(Test224.__allTests),
        testCase(Test226.__allTests),
        testCase(Test227.__allTests),
        testCase(Test231.__allTests),
        testCase(Test232.__allTests),
        testCase(Test234.__allTests),
    ]
}
#endif
