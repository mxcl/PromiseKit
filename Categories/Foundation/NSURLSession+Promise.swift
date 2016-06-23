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
        return start(try OMGHTTPURLRQ.get(URL, query) as URLRequest)
    }

    public class func POST(_ URL: String, formData: [NSObject: AnyObject]? = nil) -> URLDataPromise {
        return start(try OMGHTTPURLRQ.post(URL, formData) as URLRequest)
    }

    public class func POST(_ URL: String, multipartFormData: OMGMultipartFormData) -> URLDataPromise {
        return start(try OMGHTTPURLRQ.post(URL, multipartFormData) as URLRequest)
    }

    public class func PUT(_ URL: String) -> URLDataPromise {
        return start(try OMGHTTPURLRQ.put(URL, nil) as URLRequest)
    }

    public class func DELETE(_ URL: String) -> URLDataPromise {
        return start(try OMGHTTPURLRQ.delete(URL, nil) as URLRequest)
    }

    public func promise(_ request: URLRequest) -> URLDataPromise {
        return start(request, session: self)
    }
}

private func start(_ body: @autoclosure () throws -> URLRequest, session: URLSession = URLSession.shared()) -> URLDataPromise {
    do {
        var request = try body()

        if request.value(forHTTPHeaderField: "User-Agent") == nil {
            request.setValue(OMGUserAgent(), forHTTPHeaderField: "User-Agent")
        }

        return URLDataPromise.go(request) { completionHandler in
            let task = session.dataTask(with: request, completionHandler: completionHandler)
            task.resume()
        }
    } catch {
        return URLDataPromise(error: error)
    }
}
