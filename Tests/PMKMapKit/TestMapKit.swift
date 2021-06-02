#if !os(watchOS)

import PromiseKit
import PMKMapKit
import MapKit
import XCTest

class Test_MKDirections_Swift: XCTestCase {
    func test_directions_response() {
        let ex = expectation(description: "")

        class MockDirections: MKDirections {
            override func calculate(completionHandler: @escaping MKDirections.DirectionsHandler) {
                completionHandler(MKDirections.Response(), nil)
            }
        }

        let rq = MKDirections.Request()
        let directions = MockDirections(request: rq)

        directions.calculate().done { _ in
            ex.fulfill()
        }.cauterize()

        waitForExpectations(timeout: 5, handler: nil)
    }


    func test_ETA_response() {
        let ex = expectation(description: "")

        class MockDirections: MKDirections {
            override func calculateETA(completionHandler: @escaping MKDirections.ETAHandler) {
                completionHandler(MKDirections.ETAResponse(), nil)
            }
        }

        let rq = MKDirections.Request()
        MockDirections(request: rq).calculateETA().done { rsp in
            ex.fulfill()
        }.cauterize()

        waitForExpectations(timeout: 5, handler: nil)
    }

}

class Test_MKSnapshotter_Swift: XCTestCase {
    func test() {
        let ex = expectation(description: "")

        class MockSnapshotter: MKMapSnapshotter {
            override func start(completionHandler: @escaping MKMapSnapshotter.CompletionHandler) {
                completionHandler(MKMapSnapshotter.Snapshot(), nil)
            }
        }

        let snapshotter = MockSnapshotter()
        snapshotter.start().done { _ in
            ex.fulfill()
        }.cauterize()

        waitForExpectations(timeout: 5, handler: nil)
    }
}

#endif
