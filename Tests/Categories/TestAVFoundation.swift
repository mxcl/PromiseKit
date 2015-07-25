import AVFoundation
import PromiseKit
import XCTest

class Test_AVAudioSession_Swift: XCTestCase {
    func test() {
        let ex = expectationWithDescription("")

        AVAudioSession().requestRecordPermission().then { _ in
            ex.fulfill()
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
