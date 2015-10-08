import Foundation
import PromiseKit
import XCTest

class Test_NSTask_Swift: XCTestCase {
    func test1() {
        let ex = expectationWithDescription("")
        let task = NSTask()
        task.launchPath = "/usr/bin/basename"
        task.arguments = ["/foo/doe/bar"]
        task.promise().then { (stdout: String) -> Void in
            XCTAssertEqual(stdout, "bar\n")
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func test2() {
        let ex = expectationWithDescription("")
        let dir = "PMKAbsentDirectory"

        let task = NSTask()
        task.launchPath = "/bin/ls"
        task.arguments = [dir]

        task.promise().then { (stdout: String, stderr: String, exitStatus: Int) -> Void in
            XCTFail()
        }.error { err in
            if case NSTask.Error.Execution(let info) = err {
                let expectedStderrData = "ls: \(dir): No such file or directory\n".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!

                XCTAssertEqual(info.task, task)
                XCTAssertEqual(info.stderr, expectedStderrData)
                XCTAssertEqual(info.task.terminationStatus, 1)
                XCTAssertEqual(info.stdout.length, 0)
                ex.fulfill()
            }
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }
}
