import Foundation
import PromiseKit
import XCTest

class TestNSTask: XCTestCase {
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
            }.snatch { err in
                let userInfo = err.userInfo
                let expectedStderrData = "ls: \(dir): No such file or directory\n".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!

                XCTAssertEqual(userInfo[PMKTaskErrorLaunchPathKey] as! String, task.launchPath!)
                XCTAssertEqual(userInfo[PMKTaskErrorArgumentsKey] as! [String], task.arguments!)
                XCTAssertEqual(userInfo[PMKTaskErrorStandardErrorKey] as! NSData, expectedStderrData)
                XCTAssertEqual(userInfo[PMKTaskErrorExitStatusKey] as! Int, 1)
                XCTAssertEqual((userInfo[PMKTaskErrorStandardOutputKey] as! NSData).length, 0)
                ex.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }
}
