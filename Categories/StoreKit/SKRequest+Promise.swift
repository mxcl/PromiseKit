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
    let (promise, fulfill, reject) = Promise<SKProductsResponse>.pending()
    var retainCycle: SKDelegate?

    @objc private func request(_ request: SKRequest, didFailWithError error: NSError) {
        reject(error)
        retainCycle = nil
    }

    @objc private func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        fulfill(response)
        retainCycle = nil
    }

    @objc override class func initialize() {
        //FIXME Swift can’t see SKError, so can't do CancellableErrorProtocol
        #if os(iOS) || os(tvOS)
            NSError.registerCancelledErrorDomain(SKErrorDomain, code: SKErrorCode.paymentCancelled.rawValue)
        #else
            NSError.registerCancelledErrorDomain(SKErrorDomain, code: SKErrorCode.paymentCancelled.rawValue)
        #endif
    }
}
