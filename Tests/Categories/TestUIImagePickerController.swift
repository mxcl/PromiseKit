import KIF
import PromiseKit
import UIKit
import XCTest


class TestPromiseImagePickerController: UIKitTestCase {

    // UIImagePickerController fulfills with edited image
    func test1() {
        class Mock: UIViewController {
            var info = [String:AnyObject]()

            override func presentViewController(vc: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
                let ipc = vc as! UIImagePickerController
                after(0.05).finally {
                    ipc.delegate?.imagePickerController?(ipc, didFinishPickingMediaWithInfo: self.info)
                }
            }
        }

        let (originalImage, editedImage) = (UIImage(), UIImage())

        let mockvc = Mock()
        mockvc.info = [UIImagePickerControllerOriginalImage: originalImage, UIImagePickerControllerEditedImage: editedImage]

        let ex = expectationWithDescription("")
        mockvc.promiseViewController(UIImagePickerController(), animated: false).then { (x: UIImage) -> Void in
            XCTAssert(x == editedImage)
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    // UIImagePickerController fulfills with original image if no edited image available
    func test2() {
        class Mock: UIViewController {
            var info = [String:AnyObject]()

            override func presentViewController(vc: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
                let ipc = vc as! UIImagePickerController
                after(0.05).finally {
                    ipc.delegate?.imagePickerController?(ipc, didFinishPickingMediaWithInfo: self.info)
                }
            }
        }

        let (originalImage, editedImage) = (UIImage(), UIImage())

        let mockvc = Mock()
        mockvc.info = [UIImagePickerControllerOriginalImage: originalImage]

        let ex = expectationWithDescription("")
        mockvc.promiseViewController(UIImagePickerController(), animated: false).then { (x: UIImage) -> Void in
            XCTAssert(x == originalImage)
            XCTAssert(x != editedImage)
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    // cancelling picker cancels promise
    func test3() {
        let ex = expectationWithDescription("")
        let picker = UIImagePickerController()
        let promise: Promise<UIImage> = rootvc.promiseViewController(picker, animated: false, completion: {
            after(0.05).then { _ -> Void in
                let button = picker.viewControllers[0].navigationItem.rightBarButtonItem!
                UIControl().sendAction(button.action, to: button.target, forEvent: nil)
            }
        })
        promise.rescue { _ -> Void in
            XCTFail()
        }
        promise.rescue(policy: .AllErrors) { _ -> Void in
            after(0.5).then(ex.fulfill)
        }
        waitForExpectationsWithTimeout(10, handler: nil)

        XCTAssertNil(rootvc.presentedViewController)
    }

    // can select image from picker
    func test4() {
        let ex = expectationWithDescription("")
        let picker = UIImagePickerController()
        let promise: Promise<UIImage> = rootvc.promiseViewController(picker, animated: false, completion: {
//            after(0.05).then { _ -> Promise<Void> in
//                let tv: UITableView? = find(picker, type: UITableView.self)
//                tv?.visibleCells[1].tap()
//                return after(1.5)
//            }.then { _ -> Void in
//                let cv: UICollectionView? = find(picker.viewControllers[1], type: UICollectionView.self)
//                let cell = cv?.visibleCells()[0]
//                cell?.tap()
//            }
        })
        promise.then { img -> Void in
            XCTAssertTrue(img.size.width > 0)
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)

        XCTAssertNil(rootvc.presentedViewController)
    }

    // can select data from picker
    func test5() {
        let ex = expectationWithDescription("")
        let picker = UIImagePickerController()
        let promise: Promise<NSData> = rootvc.promiseViewController(picker, animated: false, completion: {
//            after(0.05).then { _ -> Promise<Void> in
//                let tv: UITableView? = find(picker, type: UITableView.self)
//                tv?.visibleCells[1].tap()
//                return after(1.5)
//            }.then { _ -> Void in
//                let vcs = picker.viewControllers
//                let cv: UICollectionView? = find(vcs[1], type: UICollectionView.self)
//                let cell = cv?.visibleCells()[0]
//                cell?.tap()
//            }
        })
        promise.then { data -> Void in
            XCTAssertTrue(data.length > 0)
            XCTAssertNotNil(UIImage(data: data))
            ex.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
        
        XCTAssertNil(rootvc.presentedViewController)
    }
}
