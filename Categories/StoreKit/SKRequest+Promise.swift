import StoreKit
#if !COCOAPODS
import PromiseKit
#endif

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
    let (promise, fulfill, reject) = Promise<SKProductsResponse>.pendingPromise()
    var retainCycle: SKDelegate?

#if os(iOS)
    @objc func request(request: SKRequest, didFailWithError error: NSError) {
        reject(error)
        retainCycle = nil
    }
#else
    @objc func request(request: SKRequest, didFailWithError error: NSError?) {
        reject(error!)
        retainCycle = nil
    }
#endif

    @objc func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        fulfill(response)
        retainCycle = nil
    }

    @objc override class func initialize() {
        //FIXME Swift can’t see SKError, so can't do CancellableErrorType
        #if os(iOS)
            NSError.registerCancelledErrorDomain(SKErrorDomain, code: SKErrorCode.PaymentCancelled.rawValue)
        #else
            NSError.registerCancelledErrorDomain(SKErrorDomain, code: SKErrorPaymentCancelled)
        #endif
    }
}
