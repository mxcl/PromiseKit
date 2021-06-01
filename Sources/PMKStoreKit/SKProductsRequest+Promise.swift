#if canImport(StoreKit)

#if !PMKCocoaPods
import PromiseKit
#endif
import StoreKit

/**
 To import the `SKRequest` category:

    use_frameworks!
    pod "PromiseKit/StoreKit"

 And then in your sources:

    import PromiseKit
*/
@available(watchOS 6.2, *)
extension SKProductsRequest {
    /**
     Sends the request to the Apple App Store.

     - Returns: A promise that fulfills if the request succeeds.
    */
    public func start(_: PMKNamespacer) -> Promise<SKProductsResponse> {
        let proxy = SKDelegate()
        delegate = proxy
        proxy.retainCycle = proxy
        start()
        return proxy.promise
    }
}

@available(watchOS 6.2, *)
fileprivate class SKDelegate: NSObject, SKProductsRequestDelegate {
    let (promise, seal) = Promise<SKProductsResponse>.pending()
    var retainCycle: SKDelegate?

    @objc fileprivate func request(_ request: SKRequest, didFailWithError error: Error) {
        seal.reject(error)
        retainCycle = nil
    }

    @objc fileprivate func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        seal.fulfill(response)
        retainCycle = nil
    }
}

// perhaps one day Apple will actually make their errors into Errors…
//extension SKError: CancellableError {
//    public var isCancelled: Bool {
//        return true
//    }
//}

#endif
