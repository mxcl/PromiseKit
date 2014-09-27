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

    public func promise() -> Promise<NSDictionary> {
        return self.promise().then { (data: NSData) -> Promise<NSDictionary> in
            return NSJSONFromData(data)
        }
    }

    public func promise() -> Promise<NSArray> {
        return self.promise().then { (data: NSData) -> Promise<NSArray> in
            return NSJSONFromData(data)
        }
    }
}
