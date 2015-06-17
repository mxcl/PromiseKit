import Foundation
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
    public class func GET(url: String) -> Promise<NSData> {
        return foo(try OMGHTTPURLRQ.GET(url, nil))
    }
    public class func GET(url: String) -> Promise<String> {
        return foo(try OMGHTTPURLRQ.GET(url, nil))
    }
    public class func GET(url: String) -> Promise<NSArray> {
        return foo(try OMGHTTPURLRQ.GET(url, nil))
    }
    public class func GET(url: String) -> Promise<NSDictionary> {
        return foo(try OMGHTTPURLRQ.GET(url, nil))
    }

    public class func GET(url: String, query: [String:AnyObject]) -> Promise<NSData> {
        return foo(try OMGHTTPURLRQ.GET(url, query))
    }
    public class func GET(url: String, query: [String:AnyObject]) -> Promise<String> {
        return foo(try OMGHTTPURLRQ.GET(url, query))
    }
    public class func GET(url: String, query: [String:AnyObject]) -> Promise<NSArray> {
        return foo(try OMGHTTPURLRQ.GET(url, query))
    }
    public class func GET(url: String, query: [String:AnyObject]) -> Promise<NSDictionary> {
        return foo(try OMGHTTPURLRQ.GET(url, query))
    }

    public class func POST(url: String) -> Promise<NSData> {
        return foo(try OMGHTTPURLRQ.POST(url, nil))
    }
    public class func POST(url: String) -> Promise<String> {
        return foo(try OMGHTTPURLRQ.POST(url, nil))
    }
    public class func POST(url: String) -> Promise<NSArray> {
        return foo(try OMGHTTPURLRQ.POST(url, nil))
    }
    public class func POST(url: String) -> Promise<NSDictionary> {
        return foo(try OMGHTTPURLRQ.POST(url, nil))
    }

    public class func POST(url: String, formData: [String:AnyObject]) -> Promise<NSData> {
        return foo(try OMGHTTPURLRQ.POST(url, formData))
    }
    public class func POST(url: String, formData: [String:AnyObject]) -> Promise<String> {
        return foo(try OMGHTTPURLRQ.POST(url, formData))
    }
    public class func POST(url: String, formData: [String:AnyObject]) -> Promise<NSArray> {
        return foo(try OMGHTTPURLRQ.POST(url, formData))
    }
    public class func POST(url: String, formData: [String:AnyObject]) -> Promise<NSDictionary> {
        return foo(try OMGHTTPURLRQ.POST(url, formData))
    }

    public class func POST(url: String, JSON: [String:AnyObject]) -> Promise<NSData> {
        return foo(try OMGHTTPURLRQ.POST(url, JSON: JSON))
    }
    public class func POST(url: String, JSON: [String:AnyObject]) -> Promise<String> {
        return foo(try OMGHTTPURLRQ.POST(url, JSON: JSON))
    }
    public class func POST(url: String, JSON: [String:AnyObject]) -> Promise<NSArray> {
        return foo(try OMGHTTPURLRQ.POST(url, JSON: JSON))
    }
    public class func POST(url: String, JSON: [String:AnyObject]) -> Promise<NSDictionary> {
        return foo(try OMGHTTPURLRQ.POST(url, JSON: JSON))
    }

    public class func POST(url: String, multipartFormData: OMGMultipartFormData) -> Promise<NSData> {
        return foo(try OMGHTTPURLRQ.POST(url, multipartFormData))
    }
    public class func POST(url: String, multipartFormData: OMGMultipartFormData) -> Promise<String> {
        return foo(try OMGHTTPURLRQ.POST(url, multipartFormData))
    }
    public class func POST(url: String, multipartFormData: OMGMultipartFormData) -> Promise<NSArray> {
        return foo(try OMGHTTPURLRQ.POST(url, multipartFormData))
    }
    public class func POST(url: String, multipartFormData: OMGMultipartFormData) -> Promise<NSDictionary> {
        return foo(try OMGHTTPURLRQ.POST(url, multipartFormData))
    }

    public class func PUT(url: String) -> Promise<NSData> {
        return foo(try OMGHTTPURLRQ.PUT(url, nil))
    }
    public class func PUT(url: String) -> Promise<String> {
        return foo(try OMGHTTPURLRQ.PUT(url, nil))
    }
    public class func PUT(url: String) -> Promise<NSArray> {
        return foo(try OMGHTTPURLRQ.PUT(url, nil))
    }
    public class func PUT(url: String) -> Promise<NSDictionary> {
        return foo(try OMGHTTPURLRQ.PUT(url, nil))
    }

    public class func PUT(url: String, formData: [String:AnyObject]) -> Promise<NSData> {
        return foo(try OMGHTTPURLRQ.PUT(url, formData))
    }
    public class func PUT(url: String, formData: [String:AnyObject]) -> Promise<String> {
        return foo(try OMGHTTPURLRQ.PUT(url, formData))
    }
    public class func PUT(url: String, formData: [String:AnyObject]) -> Promise<NSArray> {
        return foo(try OMGHTTPURLRQ.PUT(url, formData))
    }
    public class func PUT(url: String, formData: [String:AnyObject]) -> Promise<NSDictionary> {
        return foo(try OMGHTTPURLRQ.PUT(url, formData))
    }

    public class func PUT(url: String, JSON: [String:AnyObject]) -> Promise<NSData> {
        return foo(try OMGHTTPURLRQ.PUT(url, JSON: JSON))
    }
    public class func PUT(url: String, JSON: [String:AnyObject]) -> Promise<String> {
        return foo(try OMGHTTPURLRQ.PUT(url, JSON: JSON))
    }
    public class func PUT(url: String, JSON: [String:AnyObject]) -> Promise<NSArray> {
        return foo(try OMGHTTPURLRQ.PUT(url, JSON: JSON))
    }
    public class func PUT(url: String, JSON: [String:AnyObject]) -> Promise<NSDictionary> {
        return foo(try OMGHTTPURLRQ.PUT(url, JSON: JSON))
    }

    public class func DELETE(url: String) -> Promise<NSData> {
        return foo(try OMGHTTPURLRQ.DELETE(url, nil))
    }
    public class func DELETE(url: String) -> Promise<String> {
        return foo(try OMGHTTPURLRQ.DELETE(url, nil))
    }
    public class func DELETE(url: String) -> Promise<NSArray> {
        return foo(try OMGHTTPURLRQ.DELETE(url, nil))
    }
    public class func DELETE(url: String) -> Promise<NSDictionary> {
        return foo(try OMGHTTPURLRQ.DELETE(url, nil))
    }

    public class func promise(request: NSURLRequest) -> Promise<NSData> {
        return fetch(request).then(on: zalgo){ x, _ -> NSData in return x }
    }

    public class func promise(request: NSURLRequest) -> Promise<(NSData, NSURLResponse)> {
        return fetch(request)
    }

    public class func promise(rq: NSURLRequest) -> Promise<String> {
        return fetch(rq).then(on: zalgo) { data, rsp -> String in
            guard let str = NSString(data: data, encoding: rsp.stringEncoding ?? NSUTF8StringEncoding) else {
                throw Error.StringEncoding(rq, data, rsp)
            }
            return str as String
        }
    }

    public class func promise(request: NSURLRequest) -> Promise<NSDictionary> {
        return promise(request).then(on: waldo, NSJSONFromData)
    }

    public class func promise(request: NSURLRequest) -> Promise<NSArray> {
        return promise(request).then(on: waldo, NSJSONFromData)
    }
}


extension NSURLConnection {
    private class func foo(@autoclosure body: () throws -> NSURLRequest) -> Promise<NSData> {
        do {
            return promise(try body())
        } catch {
            return Promise(error)
        }
    }

    private class func foo(@autoclosure body: () throws -> NSURLRequest) -> Promise<String> {
        do {
            return promise(try body())
        } catch {
            return Promise(error)
        }
    }

    private class func foo(@autoclosure body: () throws -> NSURLRequest) -> Promise<NSArray> {
        do {
            return promise(try body())
        } catch {
            return Promise(error)
        }
    }

    private class func foo(@autoclosure body: () throws -> NSURLRequest) -> Promise<NSDictionary> {
        do {
            return promise(try body())
        } catch {
            return Promise(error)
        }
    }
}


#if os(iOS)
import UIKit.UIImage

extension NSURLConnection {
    /**
     Makes a GET request to the provided URL.

         NSURLConnection.GET("http://placekitten.com/320/320").then { (img: UIImage) in
             // you must specify the type for the closure
         }

     @return A promise that fulfills with the image at the specified URL.
    */
    public class func GET(url: String) -> Promise<UIImage> {
        return foo(try OMGHTTPURLRQ.GET(url, nil))
    }

    public class func GET(url: String, query: [String:String]) -> Promise<UIImage> {
        return foo(try OMGHTTPURLRQ.GET(url, query))
    }

    public class func POST(url: String, formData: [String:String]) -> Promise<UIImage> {
        return foo(try OMGHTTPURLRQ.POST(url, formData))
    }

    public class func POST(url: String, JSON: [String:String]) -> Promise<UIImage> {
        return foo(try OMGHTTPURLRQ.POST(url, JSON: JSON))
    }

    public class func POST(url: String, multipartFormData: OMGMultipartFormData) -> Promise<UIImage> {
        return foo(try OMGHTTPURLRQ.POST(url, multipartFormData))
    }

    public class func promise(rq: NSURLRequest) -> Promise<UIImage> {
        return fetch(rq).then(on: waldo) { data, _ -> UIImage in
            guard let img = UIImage(data: data), cgimg = img.CGImage else {
                throw Error.InvalidImageData(rq, data)
            }

            return UIImage(CGImage: cgimg, scale: img.scale, orientation: img.imageOrientation)
        }
    }

    private class func foo(@autoclosure body: () throws -> NSURLRequest) -> Promise<UIImage> {
        do {
            return promise(try body())
        } catch let error {
            return Promise(error)
        }
    }
}

#endif


extension NSURLResponse {
    private var stringEncoding: UInt? {
        if let encodingName = textEncodingName {
            let encoding = CFStringConvertIANACharSetNameToEncoding(encodingName)
            if encoding != kCFStringEncodingInvalidId {
                return CFStringConvertEncodingToNSStringEncoding(encoding)
            }
        }
        return nil
    }
}

private let Q = NSOperationQueue()

private func fetch(var request: NSURLRequest) -> Promise<(NSData, NSHTTPURLResponse)> {
    if request.valueForHTTPHeaderField("User-Agent") == nil {
        let rq = request.mutableCopy() as! NSMutableURLRequest
        rq.setValue(OMGUserAgent(), forHTTPHeaderField:"User-Agent")
        request = rq
    }

    return Promise { fulfill, reject in
        NSURLConnection.sendAsynchronousRequest(request, queue: Q) { rsp, data, error in
            if let error = error {
                reject(NSURLConnection.Error.UnderlyingCocoaError(request, data, rsp, error))
            } else if let data = data, rsp = rsp as? NSHTTPURLResponse where rsp.statusCode >= 200 && rsp.statusCode < 300 {
                fulfill(data, rsp)
            } else {
                reject(NSURLConnection.Error.BadResponse(request, data, rsp))
            }
        }
    }
}


extension NSURLConnection {
    public enum Error: ErrorType {
        case InvalidImageData(NSURLRequest, NSData)
        case UnderlyingCocoaError(NSURLRequest, NSData?, NSURLResponse?, NSError)
        case BadResponse(NSURLRequest, NSData?, NSURLResponse?)
        case StringEncoding(NSURLRequest, NSData, Foundation.NSHTTPURLResponse)

        public var NSHTTPURLResponse: Foundation.NSHTTPURLResponse! {
            switch self {
            case .InvalidImageData:
                return nil
            case .UnderlyingCocoaError(_, _, let rsp, _):
                return rsp as! Foundation.NSHTTPURLResponse
            case .BadResponse(_, _, let rsp):
                return rsp as! Foundation.NSHTTPURLResponse
            case .StringEncoding(_, _, let rsp):
                return rsp
            }
        }

        //        public var stringValue: String {
        //            let (data: NSData, rsp: NSURLResponse) = { () -> (NSData, NSURLResponse?) in
        //                switch self {
        //                    case .InvalidImageData(_, let data): return (data, nil)
        //                    case .UnderlyingCocoaError(_, _, let data, let rsp): return (data, rsp)
        //                    case .BadResponse(_, let data, let rsp): return (data, rsp)
        //                }
        //            }()
        //            return NSString(data: data, encoding: rsp?.stringEncoding ?? NSUTF8StringEncoding)
        //        }
    }
}
