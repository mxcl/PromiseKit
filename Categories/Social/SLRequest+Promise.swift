import PromiseKit
import Social

/**
 To import the `SLRequest` category:

    use_frameworks!
    pod "PromiseKit/Social"

 And then in your sources:

    import PromiseKit
*/
extension SLRequest {
    public func promise() -> Promise<NSData> {
        return Promise { sealant in
            performRequestWithHandler { (data, rsp, err) in
                sealant.resolve(data, err)
            }
        }
    }

    public func promise() -> Promise<NSDictionary> {
        return promise().then(on: waldo, NSJSONFromData)
    }

    public func promise() -> Promise<NSArray> {
        return promise().then(on: waldo, NSJSONFromData)
    }
}
