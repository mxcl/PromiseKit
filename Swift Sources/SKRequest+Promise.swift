import StoreKit

private class SKRequestProxy: NSObject, SKRequestDelegate {
    let (promise, fulfill, reject) = Promise<SKRequest>.defer()

    func requestDidFinish(request: SKRequest!) {
        fulfill(request)
        PMKRelease(self)
    }

    func request(request: SKRequest!, didFailWithError error: NSError!) {
        reject(error)
        PMKRelease(self)
    }
}

extension SKRequest {
    public func promise() -> Promise<SKRequest> {
        let proxy = SKRequestProxy()
        PMKRetain(proxy)
        delegate = proxy
        start()
        return proxy.promise
    }
}

private class SKProductsRequestProxy: NSObject, SKProductsRequestDelegate {
    let (promise, fulfill, reject) = Promise<SKProductsResponse>.defer()

    @objc func productsRequest(request: SKProductsRequest!, didReceiveResponse response: SKProductsResponse!) {
        fulfill(response)
        PMKRelease(self)
    }
    
    func request(request: SKRequest!, didFailWithError error: NSError!) {
        reject(error)
        PMKRelease(self)
    }
}

extension SKProductsRequest {
    public func promise() -> Promise<SKProductsResponse> {
        let proxy = SKProductsRequestProxy()
        delegate = proxy
        PMKRetain(proxy)
        start()
        return proxy.promise
    }
}
