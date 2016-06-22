import AVFoundation
import PromiseKit
import XCTest

class Test_AVAudioSession_Swift: XCTestCase {
    func test() {
        let ex = expectation(withDescription: "")

        AVAudioSession().requestRecordPermission().then { _ in
            ex.fulfill()
        }

        waitForExpectations(withTimeout: 1, handler: nil)
    }
}
