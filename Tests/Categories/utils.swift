#if os(iOS)
import XCTest
import UIKit

class UIKitTestCase: XCTestCase {

    var rootvc: UIViewController {
        return UIApplication.shared().keyWindow!.rootViewController!
    }

    override func setUp() {
        UIApplication.shared().keyWindow!.rootViewController = UIViewController()
    }

    override func tearDown() {
        UIApplication.shared().keyWindow!.rootViewController = nil
    }
}
#endif

import ObjectiveC

func swizzle(_ foo: AnyClass, _ from: Selector, isClassMethod: Bool = false, body: @noescape () -> Void) {
    let originalMethod: Method
    let swizzledMethod: Method

    if isClassMethod {
        originalMethod = class_getClassMethod(foo, from)
        swizzledMethod = class_getClassMethod(foo, Selector("pmk_\(from)"))
    } else {
        originalMethod = class_getInstanceMethod(foo, from)
        swizzledMethod = class_getInstanceMethod(foo, Selector("pmk_\(from)"))
    }

    method_exchangeImplementations(originalMethod, swizzledMethod)
    body()
    method_exchangeImplementations(swizzledMethod, originalMethod)
}
