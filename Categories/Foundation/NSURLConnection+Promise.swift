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

    public class func promise(rq: NSURLRequest) -> Promise<String> {
        return fetch(rq).then(on: zalgo) { data, rsp -> String in
            if let str = NSString(data: data, encoding: rsp.stringEncoding ?? NSUTF8StringEncoding) {
                return str as String
            } else {
                let info = [NSLocalizedDescriptionKey: "The server response was not textual"]
                throw NSError(domain: NSURLErrorDomain, code: NSURLErrorBadServerResponse, userInfo: info)
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


extension NSURLConnection {
    private class func foo(@autoclosure body: () throws -> NSURLRequest) -> Promise<NSData> {
        do {
            return promise(try body())
        } catch let error {
            return Promise(error as NSError)
        }
    }

    private class func foo(@autoclosure body: () throws -> NSURLRequest) -> Promise<String> {
        do {
            return promise(try body())
        } catch let error {
            return Promise(error as NSError)
        }
    }

    private class func foo(@autoclosure body: () throws -> NSURLRequest) -> Promise<NSArray> {
        do {
            return promise(try body())
        } catch let error {
            return Promise(error as NSError)
        }
    }

    private class func foo(@autoclosure body: () throws -> NSURLRequest) -> Promise<NSDictionary> {
        do {
            return promise(try body())
        } catch let error {
            return Promise(error as NSError)
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
            if let img = UIImage(data: data), cgimg = img.CGImage {
                return UIImage(CGImage: cgimg, scale: img.scale, orientation: img.imageOrientation)
            } else {
                let info = [NSLocalizedDescriptionKey: "The server returned invalid image data"]
                throw NSError(domain: NSURLErrorDomain, code: NSURLErrorBadServerResponse, userInfo: info)
            }
        }
    }

    private class func foo(@autoclosure body: () throws -> NSURLRequest) -> Promise<UIImage> {
        do {
            return promise(try body())
        } catch let error {
            return Promise(error as NSError)
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


private func fetch(var request: NSURLRequest) -> Promise<(NSData, NSURLResponse)> {
    if request.valueForHTTPHeaderField("User-Agent") == nil {
        let rq = request.mutableCopy() as! NSMutableURLRequest
        rq.setValue(OMGUserAgent(), forHTTPHeaderField:"User-Agent")
        request = rq
    }

    return Promise { fulfill, prereject in
        NSURLConnection.sendAsynchronousRequest(request, queue: PMKOperationQueue) { rsp, data, err in

            assert(!NSThread.isMainThread())

            func reject(error: NSError) {
                var info = error.userInfo ?? [:]
                info[NSURLErrorFailingURLErrorKey] = request.URL
                info[NSURLErrorFailingURLStringErrorKey] = request.URL?.absoluteString
                info[PMKURLErrorFailingDataKey] = data
                if let data = data {
                    info[PMKURLErrorFailingStringKey] = NSString(data: data, encoding: rsp?.stringEncoding ?? NSUTF8StringEncoding)
                }
                info[PMKURLErrorFailingURLResponseKey] = rsp
                prereject(NSError(domain: error.domain, code: error.code, userInfo: info))
            }

            if let err = err {
                reject(err)
            } else if let data = data, rsp = rsp as? NSHTTPURLResponse where rsp.statusCode >= 200 && rsp.statusCode < 300 {
                fulfill(data, rsp)
            } else {
                reject(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadServerResponse, userInfo: [
                    NSLocalizedDescriptionKey: "The server returned a bad HTTP response code"
                ]))
            }
        }
    }
}
