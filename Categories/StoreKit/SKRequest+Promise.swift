import StoreKit
import PromiseKit

/**
 To import the `SKRequest` category:

    use_frameworks!
    pod "PromiseKit/StoreKit"

 And then in your sources:

    import PromiseKit
*/
extension SKRequest {
    public func promise() -> Promise<SKProductsResponse> {
        let proxy = SKDelegate()
        delegate = proxy
        proxy.retainCycle = proxy
        start()
        return proxy.promise
    }
}


private class SKDelegate: NSObject, SKProductsRequestDelegate {
    let (promise, fulfill, reject) = Promise<SKProductsResponse>.defer()
    var retainCycle: SKDelegate?

    @objc func request(request: SKRequest!, didFailWithError error: NSError!) {
        reject(error)
        retainCycle = nil
    }

    @objc func productsRequest(request: SKProductsRequest!, didReceiveResponse response: SKProductsResponse!) {
        fulfill(response)
        retainCycle = nil
    }

    @objc override class func initialize() {
        NSError.registerCancelledErrorDomain(SKErrorDomain, code: SKErrorPaymentCancelled)
    }
}
