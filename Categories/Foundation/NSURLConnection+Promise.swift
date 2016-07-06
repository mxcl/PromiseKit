import Foundation
// When using Carthage add `github "mxcl/OMGHTTPURLRQ"` to your Cartfile.
import OMGHTTPURLRQ
#if !COCOAPODS
import PromiseKit
#endif

/**
 To import the `NSURLConnection` category:

    use_frameworks!
    pod "PromiseKit/Foundation"

 Or `NSURLConnection` is one of the categories imported by the umbrella pod:

    use_frameworks!
    pod "PromiseKit"

 And then in your sources:

    import PromiseKit
*/
extension NSURLConnection {
    public class func GET(_ URL: String, query: [NSObject:AnyObject]? = nil) -> URLDataPromise {
        return go(try OMGHTTPURLRQ.get(URL, query) as URLRequest)
    }

    public class func POST(_ URL: String, formData: [NSObject:AnyObject]? = nil) -> URLDataPromise {
        return go(try OMGHTTPURLRQ.post(URL, formData) as URLRequest)
    }

    public class func POST(_ URL: String, JSON: [NSObject:AnyObject]) -> URLDataPromise {
        return go(try OMGHTTPURLRQ.post(URL, json: JSON) as URLRequest)
    }

    public class func POST(_ URL: String, multipartFormData: OMGMultipartFormData) -> URLDataPromise {
        return go(try OMGHTTPURLRQ.post(URL, multipartFormData) as URLRequest)
    }

    public class func PUT(_ URL: String, formData: [NSObject:AnyObject]? = nil) -> URLDataPromise {
        return go(try OMGHTTPURLRQ.put(URL, formData) as URLRequest)
    }

    public class func PUT(_ URL: String, JSON: [NSObject:AnyObject]) -> URLDataPromise {
        return go(try OMGHTTPURLRQ.put(URL, json: JSON) as URLRequest)
    }

    public class func DELETE(_ URL: String) -> URLDataPromise {
        return go(try OMGHTTPURLRQ.delete(URL, nil) as URLRequest)
    }

    public class func promise(_ request: URLRequest) -> URLDataPromise {
        return go(request)
    }
}

private func go(_ body: @autoclosure () throws -> URLRequest) -> URLDataPromise {
    do {
        var request = try body()

        if request.value(forHTTPHeaderField: "User-Agent") == nil {
            request.setValue(OMGUserAgent(), forHTTPHeaderField: "User-Agent")
        }

        return URLDataPromise.go(request) { completionHandler in
            NSURLConnection.sendAsynchronousRequest(request, queue: Q, completionHandler: { completionHandler($1, $0, $2) })
        }
    } catch {
        return URLDataPromise.resolved(error: error)
    }
}

private let Q = OperationQueue()
