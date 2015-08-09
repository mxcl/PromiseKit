import Foundation
import PromiseKit
import OMGHTTPURLRQ

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
        return promise(NSURLRequest(URL:NSURL(string:url)!))
    }
    public class func GET(url: String) -> Promise<String> {
        return promise(NSURLRequest(URL:NSURL(string:url)!))
    }
    public class func GET(url: String) -> Promise<NSArray> {
        return promise(NSURLRequest(URL:NSURL(string:url)!))
    }
    public class func GET(url: String) -> Promise<NSDictionary> {
        return promise(NSURLRequest(URL:NSURL(string:url)!))
    }

    public class func GET(url: String, query: [String:AnyObject]) -> Promise<NSData> {
        return promise(OMGHTTPURLRQ.GET(url, query))
    }
    public class func GET(url: String, query: [String:AnyObject]) -> Promise<String> {
        return promise(OMGHTTPURLRQ.GET(url, query))
    }
    public class func GET(url: String, query: [String:AnyObject]) -> Promise<NSArray> {
        return promise(OMGHTTPURLRQ.GET(url, query))
    }
    public class func GET(url: String, query: [String:AnyObject]) -> Promise<NSDictionary> {
        return promise(OMGHTTPURLRQ.GET(url, query))
    }

    public class func POST(url: String, formData: [String:String]) -> Promise<NSData> {
        return promise(OMGHTTPURLRQ.POST(url, formData))
    }
    public class func POST(url: String, formData: [String:String]) -> Promise<String> {
        return promise(OMGHTTPURLRQ.POST(url, formData))
    }
    public class func POST(url: String, formData: [String:String]) -> Promise<NSArray> {
        return promise(OMGHTTPURLRQ.POST(url, formData))
    }
    public class func POST(url: String, formData: [String:String]) -> Promise<NSDictionary> {
        return promise(OMGHTTPURLRQ.POST(url, formData))
    }

    public class func POST(url: String, JSON: [String:AnyObject]) -> Promise<NSData> {
        return promise(OMGHTTPURLRQ.POST(url, JSON: JSON))
    }
    public class func POST(url: String, JSON: [String:AnyObject]) -> Promise<String> {
        return promise(OMGHTTPURLRQ.POST(url, JSON: JSON))
    }
    public class func POST(url: String, JSON: [String:AnyObject]) -> Promise<NSArray> {
        return promise(OMGHTTPURLRQ.POST(url, JSON: JSON))
    }
    public class func POST(url: String, JSON: [String:AnyObject]) -> Promise<NSDictionary> {
      return promise(OMGHTTPURLRQ.POST(url, JSON: JSON))
    }

    public class func POST(url: String, multipartFormData: OMGMultipartFormData) -> Promise<NSData> {
        return promise(OMGHTTPURLRQ.POST(url, multipartFormData))
    }
    public class func POST(url: String, multipartFormData: OMGMultipartFormData) -> Promise<String> {
        return promise(OMGHTTPURLRQ.POST(url, multipartFormData))
    }
    public class func POST(url: String, multipartFormData: OMGMultipartFormData) -> Promise<NSArray> {
        return promise(OMGHTTPURLRQ.POST(url, multipartFormData))
    }
    public class func POST(url: String, multipartFormData: OMGMultipartFormData) -> Promise<NSDictionary> {
        return promise(OMGHTTPURLRQ.POST(url, multipartFormData))
    }

    public class func promise(request: NSURLRequest) -> Promise<NSData> {
        return fetch(request).then(on: zalgo){ x, _ -> NSData in return x }
    }

    public class func promise(request: NSURLRequest) -> Promise<(NSData, NSURLResponse)> {
        return fetch(request)
    }

    public class func promise(rq: NSURLRequest) -> Promise<String> {
        return fetch(rq).then(on: zalgo) { data, rsp -> Promise<String> in
            if let str = NSString(data: data, encoding: rsp.stringEncoding ?? NSUTF8StringEncoding) {
                return Promise(str as String)
            } else {
                let info = [NSLocalizedDescriptionKey: "The server response was not textual"]
                return Promise(NSError(domain:NSURLErrorDomain, code: NSURLErrorBadServerResponse, userInfo: info))
            }
        }
    }

    public class func promise(request: NSURLRequest) -> Promise<NSDictionary> {
        return promise(request).then(on: waldo, NSJSONFromData)
    }

    public class func promise(request: NSURLRequest) -> Promise<NSArray> {
        return promise(request).then(on: waldo, NSJSONFromData)
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
        return promise(NSURLRequest(URL: NSURL(string:url)!))
    }

    public class func GET(url: String, query: [String:String]) -> Promise<UIImage> {
        return promise(OMGHTTPURLRQ.GET(url, query))
    }

    public class func POST(url: String, formData: [String:String]) -> Promise<UIImage> {
        return promise(OMGHTTPURLRQ.POST(url, formData))
    }

    public class func POST(url: String, JSON json: [String:String]) -> Promise<UIImage> {
        return promise(OMGHTTPURLRQ.POST(url, JSON: json))
    }

    public class func POST(url: String, multipartFormData: OMGMultipartFormData) -> Promise<UIImage> {
        return promise(OMGHTTPURLRQ.POST(url, multipartFormData))
    }

    public class func promise(rq: NSURLRequest) -> Promise<UIImage> {
        return fetch(rq).then(on: waldo) { data, _ in
            if let img = UIImage(data: data) {
                if let img = UIImage(CGImage:img.CGImage, scale:img.scale, orientation:img.imageOrientation) {
                    return Promise(img)
                }
            }

            let info = [NSLocalizedDescriptionKey: "The server returned invalid image data"]
            return Promise(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadServerResponse, userInfo: info))
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

private func fetch(var request: NSURLRequest) -> Promise<(NSData, NSURLResponse)> {
    if request.valueForHTTPHeaderField("User-Agent") == nil {
        let rq = request.mutableCopy() as! NSMutableURLRequest
        rq.setValue(OMGUserAgent(), forHTTPHeaderField:"User-Agent")
        request = rq
    }

    return Promise { fulfill, prereject in
        NSURLConnection.sendAsynchronousRequest(request, queue: Q) { rsp, data, err in

            assert(!NSThread.isMainThread())

            func reject(error: NSError) {
                var info = error.userInfo ?? [:]
                info[NSURLErrorFailingURLErrorKey] = request.URL
                info[NSURLErrorFailingURLStringErrorKey] = request.URL?.absoluteString
                info[PMKURLErrorFailingDataKey] = data
                if data != nil {
                    info[PMKURLErrorFailingStringKey] = NSString(data: data, encoding: rsp?.stringEncoding ?? NSUTF8StringEncoding)
                }
                info[PMKURLErrorFailingURLResponseKey] = rsp
                prereject(NSError(domain: error.domain, code: error.code, userInfo: info))
            }

            if err != nil {
                reject(err)
            } else if let response = rsp as? NSHTTPURLResponse where response.statusCode < 200 || response.statusCode >= 300 {
                reject(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadServerResponse, userInfo: [
                    NSLocalizedDescriptionKey: "The server returned a bad HTTP response code"
                    ]))
            } else {
                fulfill(data, rsp)
            }
        }
    }
}
