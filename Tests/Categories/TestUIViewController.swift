import PromiseKit
import UIKit
import XCTest

private let dummy = 1_234_765


class Test_UIViewController_Swift: UIKitTestCase {

    func test_rejects_if_vc_has_no_promise_property() {
        let ex = expectationWithDescription("")
        let p: Promise<Int> = rootvc.promiseViewController(UIViewController(), animated: false)
        p.error { error in
            if case UIViewController.Error.NotPromisable = error {
                ex.fulfill()
            }
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test_rejects_if_promise_property_returns_nil() {
        let ex = expectationWithDescription("")
        let p: Promise<Int> = rootvc.promiseViewController(MockViewController(), animated: false)
        p.error { error in
            if case UIViewController.Error.NilPromisable = error {
                ex.fulfill()
            }
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test_rejects_if_promise_property_casts_wrongly() {
        let ex = expectationWithDescription("")
        let my = MockViewController()
        my.promise = Promise(true)
        let p: Promise<Int> = rootvc.promiseViewController(my, animated: false)
        p.error { err in
            if case UIViewController.Error.NotGenericallyPromisable = err {
                ex.fulfill()
            }
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test_resolved_promise_property_means_vc_does_not_appear() {
        let ex = expectationWithDescription("")
        let my = MockViewController()
        my.promise = Promise(dummy)
        rootvc.promiseViewController(my, animated: false).then { (x: Int) -> Void in
            XCTAssertFalse(my.appeared)
            XCTAssertEqual(x, dummy)
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test_vc_dismisses_once_promise_is_resolved() {
        let ex = expectationWithDescription("")
        let my = MockViewController()
        let (promise, resolve, _) = Promise<Int>.pendingPromise()
        my.promise = promise
        rootvc.promiseViewController(my, animated: false).then { (x: Int) -> Void in
            XCTAssertTrue(my.appeared)
            XCTAssertEqual(x, dummy)
            ex.fulfill()
        }
        after(0).then {
            resolve(dummy)
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test_nav_controllers_use_their_root_vc_promise_property() {
        let ex = expectationWithDescription("")
        let nc = UINavigationController()
        let my = MockViewController()
        my.promise = after(0.1).then{ dummy }
        nc.viewControllers = [my]
        rootvc.promiseViewController(nc, animated: false).then { (x: Int) -> Void in
            XCTAssertTrue(my.appeared)
            XCTAssertEqual(x, dummy)
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }
}



private class MockViewController: UIViewController, Promisable {
    @objc var promise: AnyObject! = nil

    var appeared = false

    private override func viewDidAppear(animated: Bool) {
        appeared = true
    }
}
