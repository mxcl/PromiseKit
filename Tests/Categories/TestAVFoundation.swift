import AVFoundation
import PromiseKit
import XCTest

class Test_AVAudioSession_Swift: XCTestCase {
    func test() {
        let ex = expectation(description: "")

        AVAudioSession().requestRecordPermission().then { _ in
            ex.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }
}
