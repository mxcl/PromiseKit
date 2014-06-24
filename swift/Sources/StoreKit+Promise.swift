import StoreKit

// TODO should be possible to genericize this


class SKRequestProxy: NSObject, SKRequestDelegate {
    let fulfiller:(SKRequest) -> ()
    let rejecter:(NSError) -> ()

    init(fulfiller:(SKRequest) -> (), rejecter:(NSError) -> ()) {
        self.fulfiller = fulfiller
        self.rejecter = rejecter
        super.init()
        PMKRetain(self)
    }

    func requestDidFinish(request: SKRequest!) {
        fulfiller(request)
        PMKRelease(self)
    }
    func request(request: SKRequest!, didFailWithError error: NSError!) {
        rejecter(error)
        PMKRelease(self)
    }
}


extension SKRequest {
    func promise() -> Promise<SKRequest> {
        let deferred = Promise<SKRequest>.defer()
        delegate = SKRequestProxy(deferred.fulfiller, deferred.rejecter)
        start()
        return deferred.promise
    }
}
