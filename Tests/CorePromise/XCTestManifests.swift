import XCTest

extension AfterTests {
    static let __allTests = [
        ("testNegative", testNegative),
        ("testPositive", testPositive),
        ("testZero", testZero),
    ]
}

extension CancellationTests {
    static let __allTests = [
        ("testCancellation", testCancellation),
        ("testFoundationBridging1", testFoundationBridging1),
        ("testFoundationBridging2", testFoundationBridging2),
        ("testIsCancelled", testIsCancelled),
        ("testRecoverWithCancellation", testRecoverWithCancellation),
        ("testThrowCancellableErrorThatIsNotCancelled", testThrowCancellableErrorThatIsNotCancelled),
    ]
}

extension CatchableTests {
    static let __allTests = [
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
    static let __allTests = [
        ("testInit", testInit),
        ("testThenMap", testThenMap),
        ("testWait", testWait),
    ]
}

extension HangTests {
    static let __allTests = [
        ("test", test),
        ("testError", testError),
    ]
}

extension JoinTests {
    static let __allTests = [
        ("testFulfilledAfterAllResolve", testFulfilledAfterAllResolve),
        ("testImmediates", testImmediates),
    ]
}

extension LoggingTests {
    static let __allTests = [
        ("testCauterizeIsLogged", testCauterizeIsLogged),
        ("testGuaranteeWaitOnMainThreadLogged", testGuaranteeWaitOnMainThreadLogged),
        ("testLogging", testLogging),
        ("testPendingGuaranteeDeallocatedIsLogged", testPendingGuaranteeDeallocatedIsLogged),
        ("testPendingPromiseDeallocatedIsLogged", testPendingPromiseDeallocatedIsLogged),
        ("testPromiseWaitOnMainThreadLogged", testPromiseWaitOnMainThreadLogged),
    ]
}

extension PMKDefaultDispatchQueueTest {
    static let __allTests = [
        ("testOverrodeDefaultAlwaysQueue", testOverrodeDefaultAlwaysQueue),
        ("testOverrodeDefaultCatchQueue", testOverrodeDefaultCatchQueue),
        ("testOverrodeDefaultThenQueue", testOverrodeDefaultThenQueue),
    ]
}

extension PMKErrorTests {
    static let __allTests = [
        ("testCustomDebugStringConvertible", testCustomDebugStringConvertible),
        ("testCustomStringConvertible", testCustomStringConvertible),
    ]
}

extension PromiseTests {
    static let __allTests = [
        ("testCanMakeVoidPromise", testCanMakeVoidPromise),
        ("testCannotFulfillWithError", testCannotFulfillWithError),
        ("testCustomStringConvertible", testCustomStringConvertible),
        ("testDispatchQueueAsyncExtensionCanThrowInBody", testDispatchQueueAsyncExtensionCanThrowInBody),
        ("testDispatchQueueAsyncExtensionReturnsPromise", testDispatchQueueAsyncExtensionReturnsPromise),
        ("testIsFulfilled", testIsFulfilled),
        ("testIsPending", testIsPending),
        ("testIsRejected", testIsRejected),
        ("testIsResolved", testIsResolved),
        ("testPipeForResolved", testPipeForResolved),
        ("testThrowInFirstly", testThrowInFirstly),
        ("testThrowInInitializer", testThrowInInitializer),
        ("testWait", testWait),
    ]
}

extension RaceTests {
    static let __allTests = [
        ("test1", test1),
        ("test1Array", test1Array),
        ("test2", test2),
        ("test2Array", test2Array),
        ("testEmptyArray", testEmptyArray),
    ]
}

extension RegressionTests {
    static let __allTests = [
        ("testReturningPreviousPromiseWorks", testReturningPreviousPromiseWorks),
    ]
}

extension StressTests {
    static let __allTests = [
        ("testThenDataRace", testThenDataRace),
        ("testThensAreSequentialForLongTime", testThensAreSequentialForLongTime),
        ("testZalgoDataRace", testZalgoDataRace),
    ]
}

extension ThenableTests {
    static let __allTests = [
        ("testBarrier", testBarrier),
        ("testCompactMap", testCompactMap),
        ("testCompactMapThrows", testCompactMapThrows),
        ("testCompactMapValues", testCompactMapValues),
        ("testDispatchFlagsSyntax", testDispatchFlagsSyntax),
        ("testFirstValueForEmpty", testFirstValueForEmpty),
        ("testGet", testGet),
        ("testLastValueForEmpty", testLastValueForEmpty),
        ("testPMKErrorCompactMap", testPMKErrorCompactMap),
        ("testRejectedPromiseCompactMap", testRejectedPromiseCompactMap),
        ("testThenFlatMap", testThenFlatMap),
        ("testThenMap", testThenMap),
        ("testThenOffRejected", testThenOffRejected),
    ]
}

extension WhenConcurrentTestCase_Swift {
    static let __allTests = [
        ("testStopsDequeueingOnceRejected", testStopsDequeueingOnceRejected),
        ("testWhen", testWhen),
        ("testWhenConcurrency", testWhenConcurrency),
        ("testWhenConcurrencyLessThanZero", testWhenConcurrencyLessThanZero),
        ("testWhenEmptyGenerator", testWhenEmptyGenerator),
        ("testWhenGeneratorError", testWhenGeneratorError),
    ]
}

extension WhenTests {
    static let __allTests = [
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
    static let __allTests = [
        ("testError", testError),
        ("testInvalidCallingConvention", testInvalidCallingConvention),
        ("testInvertedCallingConvention", testInvertedCallingConvention),
        ("testIsFulfilled", testIsFulfilled),
        ("testNonOptionalFirstParameter", testNonOptionalFirstParameter),
        ("testPendingPromiseDeallocated", testPendingPromiseDeallocated),
        ("testSuccess", testSuccess),
        ("testVoidCompletionValue", testVoidCompletionValue),
        ("testVoidResolverFulfillAmbiguity", testVoidResolverFulfillAmbiguity),
    ]
}

extension ZalgoTests {
    static let __allTests = [
        ("test1", test1),
        ("test2", test2),
        ("test3", test3),
        ("test4", test4),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(AfterTests.__allTests),
        testCase(CancellationTests.__allTests),
        testCase(CatchableTests.__allTests),
        testCase(GuaranteeTests.__allTests),
        testCase(HangTests.__allTests),
        testCase(JoinTests.__allTests),
        testCase(LoggingTests.__allTests),
        testCase(PMKDefaultDispatchQueueTest.__allTests),
        testCase(PMKErrorTests.__allTests),
        testCase(PromiseTests.__allTests),
        testCase(RaceTests.__allTests),
        testCase(RegressionTests.__allTests),
        testCase(StressTests.__allTests),
        testCase(ThenableTests.__allTests),
        testCase(WhenConcurrentTestCase_Swift.__allTests),
        testCase(WhenTests.__allTests),
        testCase(WrapTests.__allTests),
        testCase(ZalgoTests.__allTests),
    ]
}
#endif
