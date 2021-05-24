#if !canImport(ObjectiveC)
import XCTest

extension AfterTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__AfterTests = [
        ("testNegative", testNegative),
        ("testPositive", testPositive),
        ("testZero", testZero),
    ]
}

extension CancellationTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__CancellationTests = [
        ("testCancellation", testCancellation),
        ("testFoundationBridging1", testFoundationBridging1),
        ("testFoundationBridging2", testFoundationBridging2),
        ("testIsCancelled", testIsCancelled),
        ("testRecoverWithCancellation", testRecoverWithCancellation),
        ("testThrowCancellableErrorThatIsNotCancelled", testThrowCancellableErrorThatIsNotCancelled),
    ]
}

extension CatchableTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__CatchableTests = [
        ("test__conditional_recover", test__conditional_recover),
        ("test__conditional_recover__fulfilled_path", test__conditional_recover__fulfilled_path),
        ("test__conditional_recover__ignores_cancellation_but_fed_cancellation", test__conditional_recover__ignores_cancellation_but_fed_cancellation),
        ("test__conditional_recover__no_recover", test__conditional_recover__no_recover),
        ("test__full_recover", test__full_recover),
        ("test__full_recover__fulfilled_path", test__full_recover__fulfilled_path),
        ("test__void_specialized_conditional_recover", test__void_specialized_conditional_recover),
        ("test__void_specialized_conditional_recover__fulfilled_path", test__void_specialized_conditional_recover__fulfilled_path),
        ("test__void_specialized_conditional_recover__ignores_cancellation_but_fed_cancellation", test__void_specialized_conditional_recover__ignores_cancellation_but_fed_cancellation),
        ("test__void_specialized_conditional_recover__no_recover", test__void_specialized_conditional_recover__no_recover),
        ("test__void_specialized_full_recover", test__void_specialized_full_recover),
        ("test__void_specialized_full_recover__fulfilled_path", test__void_specialized_full_recover__fulfilled_path),
        ("testCauterize", testCauterize),
        ("testEnsureThen_Error", testEnsureThen_Error),
        ("testEnsureThen_Value", testEnsureThen_Value),
        ("testFinally", testFinally),
    ]
}

extension GuaranteeTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__GuaranteeTests = [
        ("testCompactMapValues", testCompactMapValues),
        ("testCompactMapValuesByKeyPath", testCompactMapValuesByKeyPath),
        ("testFilterValues", testFilterValues),
        ("testFilterValuesByKeyPath", testFilterValuesByKeyPath),
        ("testFlatMapValues", testFlatMapValues),
        ("testInit", testInit),
        ("testMap", testMap),
        ("testMapByKeyPath", testMapByKeyPath),
        ("testMapValues", testMapValues),
        ("testMapValuesByKeyPath", testMapValuesByKeyPath),
        ("testNoAmbiguityForValue", testNoAmbiguityForValue),
        ("testSorted", testSorted),
        ("testSortedBy", testSortedBy),
        ("testThenFlatMap", testThenFlatMap),
        ("testThenMap", testThenMap),
        ("testWait", testWait),
    ]
}

extension HangTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__HangTests = [
        ("test", test),
        ("testError", testError),
    ]
}

extension JoinTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__JoinTests = [
        ("testFulfilledAfterAllResolve", testFulfilledAfterAllResolve),
        ("testImmediates", testImmediates),
    ]
}

extension LoggingTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__LoggingTests = [
        ("testCauterizeIsLogged", testCauterizeIsLogged),
        ("testGuaranteeWaitOnMainThreadLogged", testGuaranteeWaitOnMainThreadLogged),
        ("testLogging", testLogging),
        ("testPendingGuaranteeDeallocatedIsLogged", testPendingGuaranteeDeallocatedIsLogged),
        ("testPendingPromiseDeallocatedIsLogged", testPendingPromiseDeallocatedIsLogged),
        ("testPromiseWaitOnMainThreadLogged", testPromiseWaitOnMainThreadLogged),
    ]
}

extension PMKDefaultDispatchQueueTest {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__PMKDefaultDispatchQueueTest = [
        ("testOverrodeDefaultAlwaysQueue", testOverrodeDefaultAlwaysQueue),
        ("testOverrodeDefaultCatchQueue", testOverrodeDefaultCatchQueue),
        ("testOverrodeDefaultThenQueue", testOverrodeDefaultThenQueue),
    ]
}

extension PMKErrorTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__PMKErrorTests = [
        ("testCustomDebugStringConvertible", testCustomDebugStringConvertible),
        ("testCustomStringConvertible", testCustomStringConvertible),
    ]
}

extension PromiseTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__PromiseTests = [
        ("testCanMakeVoidPromise", testCanMakeVoidPromise),
        ("testCannotFulfillWithError", testCannotFulfillWithError),
        ("testCustomStringConvertible", testCustomStringConvertible),
        ("testDispatchQueueAsyncExtensionCanThrowInBody", testDispatchQueueAsyncExtensionCanThrowInBody),
        ("testDispatchQueueAsyncExtensionReturnsPromise", testDispatchQueueAsyncExtensionReturnsPromise),
        ("testIsFulfilled", testIsFulfilled),
        ("testIsPending", testIsPending),
        ("testIsRejected", testIsRejected),
        ("testIsResolved", testIsResolved),
        ("testNoAmbiguityForValue", testNoAmbiguityForValue),
        ("testPipeForResolved", testPipeForResolved),
        ("testThrowInFirstly", testThrowInFirstly),
        ("testThrowInInitializer", testThrowInInitializer),
        ("testWait", testWait),
    ]
}

extension RaceTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__RaceTests = [
        ("test1", test1),
        ("test1Array", test1Array),
        ("test2", test2),
        ("test2Array", test2Array),
        ("testEmptyArray", testEmptyArray),
        ("testFulfilled", testFulfilled),
        ("testFulfilledEmptyArray", testFulfilledEmptyArray),
        ("testFulfilledWithNoWinner", testFulfilledWithNoWinner),
    ]
}

extension RegressionTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__RegressionTests = [
        ("testReturningPreviousPromiseWorks", testReturningPreviousPromiseWorks),
    ]
}

extension StressTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__StressTests = [
        ("testThenDataRace", testThenDataRace),
        ("testThensAreSequentialForLongTime", testThensAreSequentialForLongTime),
        ("testZalgoDataRace", testZalgoDataRace),
    ]
}

extension ThenableTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__ThenableTests = [
        ("testBarrier", testBarrier),
        ("testCompactMap", testCompactMap),
        ("testCompactMapByKeyPath", testCompactMapByKeyPath),
        ("testCompactMapThrows", testCompactMapThrows),
        ("testCompactMapValues", testCompactMapValues),
        ("testCompactMapValuesByKeyPath", testCompactMapValuesByKeyPath),
        ("testDispatchFlagsSyntax", testDispatchFlagsSyntax),
        ("testFilterValues", testFilterValues),
        ("testFilterValuesByKeyPath", testFilterValuesByKeyPath),
        ("testFirstValueForEmpty", testFirstValueForEmpty),
        ("testGet", testGet),
        ("testLastValueForEmpty", testLastValueForEmpty),
        ("testMap", testMap),
        ("testMapByKeyPath", testMapByKeyPath),
        ("testMapValues", testMapValues),
        ("testMapValuesByKeyPath", testMapValuesByKeyPath),
        ("testPMKErrorCompactMap", testPMKErrorCompactMap),
        ("testRejectedPromiseCompactMap", testRejectedPromiseCompactMap),
        ("testThenFlatMap", testThenFlatMap),
        ("testThenMap", testThenMap),
        ("testThenOffRejected", testThenOffRejected),
    ]
}

extension WhenConcurrentTestCase_Swift {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__WhenConcurrentTestCase_Swift = [
        ("testStopsDequeueingOnceRejected", testStopsDequeueingOnceRejected),
        ("testWhen", testWhen),
        ("testWhenConcurrency", testWhenConcurrency),
        ("testWhenConcurrencyLessThanZero", testWhenConcurrencyLessThanZero),
        ("testWhenEmptyGenerator", testWhenEmptyGenerator),
        ("testWhenGeneratorError", testWhenGeneratorError),
    ]
}

extension WhenTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__WhenTests = [
        ("testAllSealedRejectedFirstOneRejects", testAllSealedRejectedFirstOneRejects),
        ("testDoubleTuple", testDoubleTuple),
        ("testEmpty", testEmpty),
        ("testGuaranteeWhen", testGuaranteeWhen),
        ("testInt", testInt),
        ("testProgress", testProgress),
        ("testProgressDoesNotExceed100Percent", testProgressDoesNotExceed100Percent),
        ("testQuadrupleTuple", testQuadrupleTuple),
        ("testQuintupleTuple", testQuintupleTuple),
        ("testRejected", testRejected),
        ("testTripleTuple", testTripleTuple),
        ("testUnhandledErrorHandlerDoesNotFire", testUnhandledErrorHandlerDoesNotFire),
        ("testUnhandledErrorHandlerDoesNotFireForStragglers", testUnhandledErrorHandlerDoesNotFireForStragglers),
        ("testVoid", testVoid),
    ]
}

extension WrapTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__WrapTests = [
        ("testError", testError),
        ("testInvalidCallingConvention", testInvalidCallingConvention),
        ("testInvertedCallingConvention", testInvertedCallingConvention),
        ("testIsFulfilled", testIsFulfilled),
        ("testNonOptionalFirstParameter", testNonOptionalFirstParameter),
        ("testPendingPromiseDeallocated", testPendingPromiseDeallocated),
        ("testSuccess", testSuccess),
        ("testSwiftResultError", testSwiftResultError),
        ("testSwiftResultSuccess", testSwiftResultSuccess),
        ("testVoidCompletionValue", testVoidCompletionValue),
        ("testVoidResolverFulfillAmbiguity", testVoidResolverFulfillAmbiguity),
    ]
}

extension ZalgoTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__ZalgoTests = [
        ("test1", test1),
        ("test2", test2),
        ("test3", test3),
        ("test4", test4),
    ]
}

public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(AfterTests.__allTests__AfterTests),
        testCase(CancellationTests.__allTests__CancellationTests),
        testCase(CatchableTests.__allTests__CatchableTests),
        testCase(GuaranteeTests.__allTests__GuaranteeTests),
        testCase(HangTests.__allTests__HangTests),
        testCase(JoinTests.__allTests__JoinTests),
        testCase(LoggingTests.__allTests__LoggingTests),
        testCase(PMKDefaultDispatchQueueTest.__allTests__PMKDefaultDispatchQueueTest),
        testCase(PMKErrorTests.__allTests__PMKErrorTests),
        testCase(PromiseTests.__allTests__PromiseTests),
        testCase(RaceTests.__allTests__RaceTests),
        testCase(RegressionTests.__allTests__RegressionTests),
        testCase(StressTests.__allTests__StressTests),
        testCase(ThenableTests.__allTests__ThenableTests),
        testCase(WhenConcurrentTestCase_Swift.__allTests__WhenConcurrentTestCase_Swift),
        testCase(WhenTests.__allTests__WhenTests),
        testCase(WrapTests.__allTests__WrapTests),
        testCase(ZalgoTests.__allTests__ZalgoTests),
    ]
}
#endif
