import Foundation
// When using Carthage add `github "mxcl/OMGHTTPURLRQ"` to your Cartfile.
import OMGHTTPURLRQ
#if !COCOAPODS
import PromiseKit
#endif

//TODO cancellation

/**
 To import the `NSURLSession` category:

    use_frameworks!
    pod "PromiseKit/Foundation"

 Or `NSURLSession` is one of the categories imported by the umbrella pod:

    use_frameworks!
    pod "PromiseKit"

 And then in your sources:

    import PromiseKit

 We provide convenience categories for the `sharedSession`, or 
 an instance method `promise`. If you need more complicated behavior
 we recommend wrapping that usage in a Promise initializer.
*/
extension URLSession {
    public class func GET(_ URL: String, query: [NSObject: AnyObject]? = nil) -> URLDataPromise {
        return start(try OMGHTTPURLRQ.GET(URL, query))
    }

    public class func POST(_ URL: String, formData: [NSObject: AnyObject]? = nil) -> URLDataPromise {
        return start(try OMGHTTPURLRQ.POST(URL, formData))
    }

    public class func POST(_ URL: String, multipartFormData: OMGMultipartFormData) -> URLDataPromise {
        return start(try OMGHTTPURLRQ.POST(URL, multipartFormData))
    }

    public class func PUT(_ URL: String) -> URLDataPromise {
        return start(try OMGHTTPURLRQ.PUT(URL, nil))
    }

    public class func DELETE(_ URL: String) -> URLDataPromise {
        return start(try OMGHTTPURLRQ.DELETE(URL, nil))
    }

    public func promise(_ request: URLRequest) -> URLDataPromise {
        return start(request, session: self)
    }
}

private func start(@autoclosure _ body: () throws -> URLRequest, session: URLSession = URLSession.shared()) -> URLDataPromise {
    do {
        var request = try body()

        if request.value(forHTTPHeaderField: "User-Agent") == nil {
            let rq = request.mutableCopy() as! NSMutableURLRequest
            rq.setValue(OMGUserAgent(), forHTTPHeaderField: "User-Agent")
            request = rq
        }

        return URLDataPromise.go(request) { completionHandler in
            let task = session.dataTask(with: request, completionHandler: completionHandler)
            task.resume()
        }
    } catch {
        return URLDataPromise(error: error)
    }
}
