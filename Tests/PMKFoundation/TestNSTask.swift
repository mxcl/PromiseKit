import PMKFoundation
import Foundation
import PromiseKit
import XCTest

#if os(macOS)

class NSTaskTests: XCTestCase {
    func test1() {
        let ex = expectation(description: "")
        let task = Process()
        task.launchPath = "/usr/bin/basename"
        task.arguments = ["/foo/doe/bar"]
        task.launch(.promise).done { stdout, _ in
            let stdout = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
            XCTAssertEqual(stdout, "bar\n")
            ex.fulfill()
        }.cauterize()
        waitForExpectations(timeout: 10)
    }

    func test2() {
        let ex = expectation(description: "")
        let dir = "PMKAbsentDirectory"

        let task = Process()
        task.launchPath = "/bin/ls"
        task.arguments = [dir]

        task.launch(.promise).done { _ in
            XCTFail()
        }.catch { err in
            do {
                throw err
            } catch Process.PMKError.execution(let proc, let stdout, let stderr) {
                let expectedStderr = "ls: \(dir): No such file or directory\n"

                XCTAssertEqual(stderr, expectedStderr)
                XCTAssertEqual(proc.terminationStatus, 1)
                XCTAssertEqual(stdout?.count ?? 0, 0)
            } catch {
                XCTFail()
            }
            ex.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
}

#endif
