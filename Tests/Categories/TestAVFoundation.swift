import AVFoundation
import PromiseKit
import XCTest

class TestAVAudioSession: XCTestCase {
    func test() {
        let ex = expectationWithDescription("")

        AVAudioSession().requestRecordPermission().then { _ in
            ex.fulfill()
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
