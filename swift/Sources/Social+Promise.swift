import Social

extension SLRequest {
    func promise() -> Promise<NSData> {
        return Promise { (fulfiller, rejecter) in
            self.performRequestWithHandler { (data, rsp, err) in
                if err {
                    rejecter(err)
                } else {
                    fulfiller(data)
                }
            }
        }
    }
}
