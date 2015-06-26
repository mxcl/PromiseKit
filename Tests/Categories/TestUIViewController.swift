import MessageUI
import PromiseKit
import UIKit
import XCTest
import KIF

class TestPromisableViewController: UIKitTestCase {

    private class MyViewController: UIViewController, Promisable {
        @objc var promise: AnyObject! = nil

        var appeared = false

        private override func viewDidAppear(animated: Bool) {
            appeared = true
        }
    }

    // fails if promised ViewController has no promise property
    func test1a() {
        let ex = expectationWithDescription("")
        let p: Promise<Int> = rootvc.promiseViewController(UIViewController(), animated: false)
        p.report { error in
            let err = error as NSError
            XCTAssertEqual(err.domain, PMKErrorDomain)
            XCTAssertEqual(err.code, PMKInvalidUsageError)
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    // fails if promised ViewController has nil promise property
    func test1b() {
        let ex = expectationWithDescription("")
        let p: Promise<Int> = rootvc.promiseViewController(MyViewController(), animated: false)
        p.report { err in
            let error = err as NSError
            XCTAssertEqual(error.domain, PMKErrorDomain)
            XCTAssertEqual(error.code, PMKInvalidUsageError)
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    // fails if promised ViewController has promise property of wrong specialization
    func test1c() {
        let ex = expectationWithDescription("")
        let my = MyViewController()
        my.promise = Promise(true)
        let p: Promise<Int> = rootvc.promiseViewController(my, animated: false)
        p.report { err in
            let error = err as NSError
            XCTAssertEqual(error.domain, PMKErrorDomain)
            XCTAssertEqual(error.code, PMKInvalidUsageError)
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    // A ViewController with a resolved promise does not appear
    func test2a() {
        let ex = expectationWithDescription("")
        let my = MyViewController()
        my.promise = Promise(dummy)
        rootvc.promiseViewController(my, animated: false).then { (x: Int) -> Void in
            XCTAssertFalse(my.appeared)
            XCTAssertEqual(x, dummy)
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    // A ViewController with an unresolved promise appears and disappears once resolved
    func test2b() {
        let ex = expectationWithDescription("")
        let my = MyViewController()
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

    // promised nav controllers use their root vc’s promise property
    func test3() {
        let ex = expectationWithDescription("")
        let nc = UINavigationController()
        let my = MyViewController()
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


/////////////////////////////////////////////////////////////// resources

private let dummy = 1_234_765


class UIKitTestCase: XCTestCase {
    var rootvc: UIViewController {
        return UIApplication.sharedApplication().keyWindow!.rootViewController!
    }

    override func setUp() {
        UIApplication.sharedApplication().keyWindow!.rootViewController = UIViewController()
    }

    override func tearDown() {
        UIApplication.sharedApplication().keyWindow!.rootViewController = nil
    }
}

func subviewsOf(v: UIView) -> [UIView] {
    return v.subviews.flatMap(subviewsOf)
}

func find<T>(vc: UIViewController, type: AnyClass) -> T? {
    return find(vc.view, type: type)
}

func find<T>(view: UIView, type: AnyClass) -> T? {
    for x in subviewsOf(view) {
        if x is T {
            return x as? T
        }
    }
    return nil
}


extension XCTestCase {
    func tester(file : String = __FILE__, _ line : Int = __LINE__) -> KIFUITestActor {
        return KIFUITestActor(inFile: file, atLine: line, delegate: self)
    }

    func system(file : String = __FILE__, _ line : Int = __LINE__) -> KIFSystemTestActor {
        return KIFSystemTestActor(inFile: file, atLine: line, delegate: self)
    }
}
