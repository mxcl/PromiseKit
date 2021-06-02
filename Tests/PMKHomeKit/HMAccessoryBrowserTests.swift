//
//  HMAccessoryBrowserTests.swift
//  PMKHKTests
//
//  Created by Chris Chares on 7/25/18.
//  Copyright © 2018 Max Howell. All rights reserved.
//

#if canImport(HomeKit) && !os(tvOS) && !os(watchOS)

import XCTest
import PromiseKit
import HomeKit
@testable import PMKHomeKit

class HMAccessoryBrowserTests: XCTestCase {
    
    func testBrowserScanReturningFirst() {
        swizzle(HMAccessoryBrowser.self, #selector(HMAccessoryBrowser.startSearchingForNewAccessories)) {
            let ex = expectation(description: "")
            
            HMPromiseAccessoryBrowser().start(scanInterval: .returnFirst(timeout: 0.5))
            .done { accessories in
                XCTAssertEqual(accessories.count, 1)
                ex.fulfill()
            }.cauterize()
            
            waitForExpectations(timeout: 5, handler: nil)
        }
    }
    
    func testBrowserScanReturningTimeout() {
        let ex = expectation(description: "")
        
        HMPromiseAccessoryBrowser().start(scanInterval: .returnFirst(timeout: 0.5))
        .catch { error in
            // Why would we have discovered anything?
            ex.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
}

extension HMAccessoryBrowser {
    @objc func pmk_startSearchingForNewAccessories() {
        after(.milliseconds(100))
        .done { swag in
            self.delegate!.accessoryBrowser?(self, didFindNewAccessory: MockAccessory())
        }
    }
}

/// Mocks
class MockAccessory: HMAccessory {
    var _uniqueID: UUID = UUID()
    override var uniqueIdentifier: UUID { return _uniqueID }
    
    override init() {
        super.init()
    }
}

// Utilty taken from https://github.com/PromiseKit/CoreLocation/blob/master/Tests/CLLocationManagerTests.swift
import ObjectiveC

func swizzle(_ foo: AnyClass, _ from: Selector, isClassMethod: Bool = false, body: () -> Void) {
    let originalMethod: Method
    let swizzledMethod: Method
    
    if isClassMethod {
        originalMethod = class_getClassMethod(foo, from)!
        swizzledMethod = class_getClassMethod(foo, Selector("pmk_\(from)"))!
    } else {
        originalMethod = class_getInstanceMethod(foo, from)!
        swizzledMethod = class_getInstanceMethod(foo, Selector("pmk_\(from)"))!
    }
    
    method_exchangeImplementations(originalMethod, swizzledMethod)
    body()
    method_exchangeImplementations(swizzledMethod, originalMethod)
}

#endif
