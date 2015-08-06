import Social
#if !COCOAPODS
import PromiseKit
#endif

/**
 To import the `SLRequest` category:

    use_frameworks!
    pod "PromiseKit/Social"

 And then in your sources:

    import PromiseKit
*/
extension SLRequest {
    public func promise() -> URLDataPromise {
        return URLDataPromise.go(preparedURLRequest()) { completionHandler in
            performRequestWithHandler(completionHandler)
        }
    }
}
