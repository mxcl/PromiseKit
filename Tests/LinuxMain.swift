import XCTest
import A_
import Core

XCTMain([
    testCase(RaceTests.allTests),
    testCase(ThenableTests.allTests),
    testCase(PMKErrorTests.allTests),
    testCase(ZalgoTests.allTests),
    testCase(CancellationTests.allTests),
    testCase(WhenConcurrentTestCase_Swift.allTests),
    testCase(HangTests.allTests),
    testCase(JoinTests.allTests),
    testCase(GuaranteeTests.allTests),
    testCase(StressTests.allTests),
    testCase(PMKDefaultDispatchQueueTest.allTests),
    testCase(PromiseTests.allTests),
    testCase(CatchableTests.allTests),
    testCase(AfterTests.allTests),
    testCase(RegressionTests.allTests),
    testCase(WrapTests.allTests),
    testCase(WhenTests.allTests),
    testCase(Test226.allTests),
    testCase(Test232.allTests),
    testCase(Test224.allTests),
    testCase(Test234.allTests),
    testCase(Test222.allTests),
    testCase(Test213.allTests),
    testCase(Test231.allTests),
    testCase(Test227.allTests),
    testCase(Test223.allTests),
    testCase(Test212.allTests)
])
