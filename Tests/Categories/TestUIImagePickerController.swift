import PromiseKit
import UIKit
import XCTest

class Test_UIImagePickerController_Swift: XCTestCase {
    func test_fulfills_with_edited_image() {
        class Mock: UIViewController {
            var info = [String:AnyObject]()

            override func present(_ vc: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
                let ipc = vc as! UIImagePickerController
                after(interval: 0.05).always {
                    ipc.delegate?.imagePickerController?(ipc, didFinishPickingMediaWithInfo: self.info)
                }
            }
        }

        let (originalImage, editedImage) = (UIImage(), UIImage())

        let mockvc = Mock()
        mockvc.info = [UIImagePickerControllerOriginalImage: originalImage, UIImagePickerControllerEditedImage: editedImage]

        let ex = expectation(description: "")
        mockvc.promiseViewController(UIImagePickerController(), animated: false).then { (x: UIImage) -> Void in
            XCTAssert(x == editedImage)
            ex.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func test_fulfills_with_original_image_if_no_edited_image() {
        class Mock: UIViewController {
            var info = [String:AnyObject]()

            override func present(_ vc: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
                let ipc = vc as! UIImagePickerController
                after(interval: 0.05).always {
                    ipc.delegate?.imagePickerController?(ipc, didFinishPickingMediaWithInfo: self.info)
                }
            }
        }

        let (originalImage, editedImage) = (UIImage(), UIImage())

        let mockvc = Mock()
        mockvc.info = [UIImagePickerControllerOriginalImage: originalImage]

        let ex = expectation(description: "")
        mockvc.promiseViewController(UIImagePickerController(), animated: false).then { (x: UIImage) -> Void in
            XCTAssert(x == originalImage)
            XCTAssert(x != editedImage)
            ex.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
    }
}
