import Social

extension SLRequest {
    public func promise() -> Promise<NSData> {
        return Promise { (fulfiller, rejecter) in
            self.performRequestWithHandler { (data, rsp, err) in
                if err != nil {
                    rejecter(err)
                } else {
                    fulfiller(data)
                }
            }
        }
    }
}
