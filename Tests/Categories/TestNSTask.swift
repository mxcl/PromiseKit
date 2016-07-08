import Foundation
import PromiseKit
import XCTest

class Test_NSTask_Swift: XCTestCase {
    func test1() {
        let ex = expectation(description: "")
        let task = Task()
        task.launchPath = "/usr/bin/basename"
        task.arguments = ["/foo/doe/bar"]
        task.promise().then { (stdout: String) -> Void in
            XCTAssertEqual(stdout, "bar\n")
            ex.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    func test2() {
        let ex = expectation(description: "")
        let dir = "PMKAbsentDirectory"

        let task = Task()
        task.launchPath = "/bin/ls"
        task.arguments = [dir]

        task.promise().then { (stdout: String, stderr: String, exitStatus: Int) -> Void in
            XCTFail()
        }.catch { err in
            if case NSTask.Error.execution(let info) = err {
                let expectedStderrData = "ls: \(dir): No such file or directory\n".data(using: .utf8, allowLossyConversion: false)!

                XCTAssertEqual(info.task, task)
                XCTAssertEqual(info.stderr, expectedStderrData)
                XCTAssertEqual(info.task.terminationStatus, 1)
                XCTAssertEqual(info.stdout.count, 0)
                ex.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }
}
