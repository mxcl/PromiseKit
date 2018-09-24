// Generated using Sourcery 0.10.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT


@testable import CorePromise
@testable import A_
import XCTest

//TODO get this to run on CI and don’t have it committed
//NOTE problem is Sourcery doesn’t support Linux currently
//USAGE: cd PromiseKit/Sources/.. && sourcery --config .github/sourcery.yml

extension AfterTests {
    static var allTests = [
        ("testZero", AfterTests.testZero),
        ("testNegative", AfterTests.testNegative),
        ("testPositive", AfterTests.testPositive),
    ]
}

extension CancellationTests {
    static var allTests = [
        ("testCancellation", CancellationTests.testCancellation),
        ("testThrowCancellableErrorThatIsNotCancelled", CancellationTests.testThrowCancellableErrorThatIsNotCancelled),
        ("testRecoverWithCancellation", CancellationTests.testRecoverWithCancellation),
        ("testFoundationBridging1", CancellationTests.testFoundationBridging1),
        ("testFoundationBridging2", CancellationTests.testFoundationBridging2),
        ("testIsCancelled", CancellationTests.testIsCancelled),
        ("testIsCancelled", CancellationTests.testIsCancelled),
    ]
}

extension CatchableTests {
    static var allTests = [
        ("testFinally", CatchableTests.testFinally),
        ("testCauterize", CatchableTests.testCauterize),
        ("test__void_specialized_full_recover", CatchableTests.test__void_specialized_full_recover),
        ("test__void_specialized_full_recover__fulfilled_path", CatchableTests.test__void_specialized_full_recover__fulfilled_path),
        ("test__void_specialized_conditional_recover", CatchableTests.test__void_specialized_conditional_recover),
        ("test__void_specialized_conditional_recover__no_recover", CatchableTests.test__void_specialized_conditional_recover__no_recover),
        ("test__void_specialized_conditional_recover__ignores_cancellation_but_fed_cancellation", CatchableTests.test__void_specialized_conditional_recover__ignores_cancellation_but_fed_cancellation),
        ("test__void_specialized_conditional_recover__fulfilled_path", CatchableTests.test__void_specialized_conditional_recover__fulfilled_path),
        ("test__full_recover", CatchableTests.test__full_recover),
        ("test__full_recover__fulfilled_path", CatchableTests.test__full_recover__fulfilled_path),
        ("test__conditional_recover", CatchableTests.test__conditional_recover),
        ("test__conditional_recover__no_recover", CatchableTests.test__conditional_recover__no_recover),
        ("test__conditional_recover__ignores_cancellation_but_fed_cancellation", CatchableTests.test__conditional_recover__ignores_cancellation_but_fed_cancellation),
        ("test__conditional_recover__fulfilled_path", CatchableTests.test__conditional_recover__fulfilled_path),
    ]
}

extension GuaranteeTests {
    static var allTests = [
        ("testInit", GuaranteeTests.testInit),
        ("testWait", GuaranteeTests.testWait),
    ]
}

extension HangTests {
    static var allTests = [
        ("test", HangTests.test),
        ("testError", HangTests.testError),
    ]
}

extension JoinTests {
    static var allTests = [
        ("testImmediates", JoinTests.testImmediates),
        ("testFulfilledAfterAllResolve", JoinTests.testFulfilledAfterAllResolve),
    ]
}

extension PMKDefaultDispatchQueueTest {
    static var allTests = [
        ("testOverrodeDefaultThenQueue", PMKDefaultDispatchQueueTest.testOverrodeDefaultThenQueue),
        ("testOverrodeDefaultCatchQueue", PMKDefaultDispatchQueueTest.testOverrodeDefaultCatchQueue),
        ("testOverrodeDefaultAlwaysQueue", PMKDefaultDispatchQueueTest.testOverrodeDefaultAlwaysQueue),
    ]
}

extension PMKErrorTests {
    static var allTests = [
        ("testCustomStringConvertible", PMKErrorTests.testCustomStringConvertible),
        ("testCustomDebugStringConvertible", PMKErrorTests.testCustomDebugStringConvertible),
    ]
}

extension PromiseTests {
    static var allTests = [
        ("testIsPending", PromiseTests.testIsPending),
        ("testIsResolved", PromiseTests.testIsResolved),
        ("testIsFulfilled", PromiseTests.testIsFulfilled),
        ("testIsRejected", PromiseTests.testIsRejected),
        ("testDispatchQueueAsyncExtensionReturnsPromise", PromiseTests.testDispatchQueueAsyncExtensionReturnsPromise),
        ("testDispatchQueueAsyncExtensionCanThrowInBody", PromiseTests.testDispatchQueueAsyncExtensionCanThrowInBody),
        ("testCustomStringConvertible", PromiseTests.testCustomStringConvertible),
        ("testCannotFulfillWithError", PromiseTests.testCannotFulfillWithError),
        ("testCanMakeVoidPromise", PromiseTests.testCanMakeVoidPromise),
        ("testCanMakeVoidPromise", PromiseTests.testCanMakeVoidPromise),
        ("testThrowInInitializer", PromiseTests.testThrowInInitializer),
        ("testThrowInFirstly", PromiseTests.testThrowInFirstly),
        ("testWait", PromiseTests.testWait),
        ("testPipeForResolved", PromiseTests.testPipeForResolved),
    ]
}

extension RaceTests {
    static var allTests = [
        ("test1", RaceTests.test1),
        ("test2", RaceTests.test2),
        ("test1Array", RaceTests.test1Array),
        ("test2Array", RaceTests.test2Array),
        ("testEmptyArray", RaceTests.testEmptyArray),
    ]
}

extension RegressionTests {
    static var allTests = [
        ("testReturningPreviousPromiseWorks", RegressionTests.testReturningPreviousPromiseWorks),
    ]
}

extension StressTests {
    static var allTests = [
        ("testThenDataRace", StressTests.testThenDataRace),
        ("testThensAreSequentialForLongTime", StressTests.testThensAreSequentialForLongTime),
        ("testZalgoDataRace", StressTests.testZalgoDataRace),
    ]
}

extension Test212 {
    static var allTests = [
        ("test", Test212.test),
    ]
}

extension Test213 {
    static var allTests = [
        ("test", Test213.test),
    ]
}

extension Test222 {
    static var allTests = [
        ("test", Test222.test),
    ]
}

extension Test223 {
    static var allTests = [
        ("test", Test223.test),
    ]
}

extension Test224 {
    static var allTests = [
        ("test", Test224.test),
    ]
}

extension Test226 {
    static var allTests = [
        ("test", Test226.test),
    ]
}

extension Test227 {
    static var allTests = [
        ("test", Test227.test),
    ]
}

extension Test231 {
    static var allTests = [
        ("test", Test231.test),
    ]
}

extension Test232 {
    static var allTests = [
        ("test", Test232.test),
    ]
}

extension Test234 {
    static var allTests = [
        ("test", Test234.test),
    ]
}

extension ThenableTests {
    static var allTests = [
        ("testGet", ThenableTests.testGet),
        ("testCompactMap", ThenableTests.testCompactMap),
        ("testCompactMapThrows", ThenableTests.testCompactMapThrows),
        ("testRejectedPromiseCompactMap", ThenableTests.testRejectedPromiseCompactMap),
        ("testPMKErrorCompactMap", ThenableTests.testPMKErrorCompactMap),
        ("testCompactMapValues", ThenableTests.testCompactMapValues),
        ("testThenMap", ThenableTests.testThenMap),
        ("testThenFlatMap", ThenableTests.testThenFlatMap),
        ("testLastValueForEmpty", ThenableTests.testLastValueForEmpty),
        ("testFirstValueForEmpty", ThenableTests.testFirstValueForEmpty),
        ("testThenOffRejected", ThenableTests.testThenOffRejected),
    ]
}

extension WhenConcurrentTestCase_Swift {
    static var allTests = [
        ("testWhen", WhenConcurrentTestCase_Swift.testWhen),
        ("testWhenEmptyGenerator", WhenConcurrentTestCase_Swift.testWhenEmptyGenerator),
        ("testWhenGeneratorError", WhenConcurrentTestCase_Swift.testWhenGeneratorError),
        ("testWhenConcurrency", WhenConcurrentTestCase_Swift.testWhenConcurrency),
        ("testWhenConcurrencyLessThanZero", WhenConcurrentTestCase_Swift.testWhenConcurrencyLessThanZero),
        ("testStopsDequeueingOnceRejected", WhenConcurrentTestCase_Swift.testStopsDequeueingOnceRejected),
    ]
}

extension WhenTests {
    static var allTests = [
        ("testEmpty", WhenTests.testEmpty),
        ("testInt", WhenTests.testInt),
        ("testDoubleTuple", WhenTests.testDoubleTuple),
        ("testTripleTuple", WhenTests.testTripleTuple),
        ("testQuadrupleTuple", WhenTests.testQuadrupleTuple),
        ("testQuintupleTuple", WhenTests.testQuintupleTuple),
        ("testVoid", WhenTests.testVoid),
        ("testRejected", WhenTests.testRejected),
        ("testProgress", WhenTests.testProgress),
        ("testProgressDoesNotExceed100Percent", WhenTests.testProgressDoesNotExceed100Percent),
        ("testUnhandledErrorHandlerDoesNotFire", WhenTests.testUnhandledErrorHandlerDoesNotFire),
        ("testUnhandledErrorHandlerDoesNotFireForStragglers", WhenTests.testUnhandledErrorHandlerDoesNotFireForStragglers),
        ("testAllSealedRejectedFirstOneRejects", WhenTests.testAllSealedRejectedFirstOneRejects),
        ("testGuaranteeWhen", WhenTests.testGuaranteeWhen),
    ]
}

extension WrapTests {
    static var allTests = [
        ("testSuccess", WrapTests.testSuccess),
        ("testError", WrapTests.testError),
        ("testInvalidCallingConvention", WrapTests.testInvalidCallingConvention),
        ("testInvertedCallingConvention", WrapTests.testInvertedCallingConvention),
        ("testNonOptionalFirstParameter", WrapTests.testNonOptionalFirstParameter),
        ("testVoidCompletionValue", WrapTests.testVoidCompletionValue),
        ("testVoidCompletionValue", WrapTests.testVoidCompletionValue),
        ("testIsFulfilled", WrapTests.testIsFulfilled),
        ("testPendingPromiseDeallocated", WrapTests.testPendingPromiseDeallocated),
    ]
}

extension ZalgoTests {
    static var allTests = [
        ("test1", ZalgoTests.test1),
        ("test2", ZalgoTests.test2),
        ("test3", ZalgoTests.test3),
        ("test4", ZalgoTests.test4),
    ]
}

XCTMain([
    testCase(AfterTests.allTests),
    testCase(CancellationTests.allTests),
    testCase(CatchableTests.allTests),
    testCase(GuaranteeTests.allTests),
    testCase(HangTests.allTests),
    testCase(JoinTests.allTests),
    testCase(PMKDefaultDispatchQueueTest.allTests),
    testCase(PMKErrorTests.allTests),
    testCase(PromiseTests.allTests),
    testCase(RaceTests.allTests),
    testCase(RegressionTests.allTests),
    testCase(StressTests.allTests),
    testCase(Test212.allTests),
    testCase(Test213.allTests),
    testCase(Test222.allTests),
    testCase(Test223.allTests),
    testCase(Test224.allTests),
    testCase(Test226.allTests),
    testCase(Test227.allTests),
    testCase(Test231.allTests),
    testCase(Test232.allTests),
    testCase(Test234.allTests),
    testCase(ThenableTests.allTests),
    testCase(WhenConcurrentTestCase_Swift.allTests),
    testCase(WhenTests.allTests),
    testCase(WrapTests.allTests),
    testCase(ZalgoTests.allTests),
])
