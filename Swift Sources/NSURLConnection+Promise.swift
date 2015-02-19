import Foundation
import OMGHTTPURLRQ


extension NSURLResponse {
    private var stringEncoding: UInt {
        if let encodingName = textEncodingName {
            let encoding = CFStringConvertIANACharSetNameToEncoding(encodingName)
            if encoding != kCFStringEncodingInvalidId {
                return CFStringConvertEncodingToNSStringEncoding(encoding)
            }
        }
        return NSUTF8StringEncoding
    }
}


private func fetch<T>(var request: NSURLRequest, body: ((T) -> Void, (NSError) -> Void, NSData, NSURLResponse) -> Void) -> Promise<T> {
    if request.valueForHTTPHeaderField("User-Agent") == nil {
        let rq = request.mutableCopy() as NSMutableURLRequest
        rq.setValue(OMGUserAgent(), forHTTPHeaderField:"User-Agent")
        request = rq
    }

    return Promise<T> { (fulfiller, rejunker) in
        NSURLConnection.sendAsynchronousRequest(request, queue:Q) { (rsp, data, err) in

            assert(!NSThread.isMainThread())

            //TODO handle non 2xx responses
            //TODO in the event of a non 2xx rsp, try to parse JSON out of the response anyway

            func rejecter(error: NSError) {
                let info = NSMutableDictionary(dictionary: error.userInfo ?? [:])
                info[NSURLErrorFailingURLErrorKey] = request.URL
                info[NSURLErrorFailingURLStringErrorKey] = request.URL.absoluteString
                if data != nil {
                    info[PMKURLErrorFailingDataKey] = data!
                    if let str = NSString(data: data, encoding: rsp.stringEncoding) {
                        info[PMKURLErrorFailingStringKey] = str
                    }
                }
                if rsp != nil { info[PMKURLErrorFailingURLResponseKey] = rsp! }
                rejunker(NSError(domain:error.domain, code:error.code, userInfo:info))
            }

            if err != nil {
                rejecter(err)
            } else {
                body(fulfiller, rejecter, data!, rsp)
            }
        }
    }
}

func NSJSONFromData(data: NSData) -> Promise<NSArray> {
    // work around ever-so-common Rails issue: https://github.com/rails/rails/issues/1742
    if data.isEqualToData(NSData(bytes: " ", length: 1)) {
        return Promise(value: NSArray())  // couldn’t do T() in generic function
    }
    return NSJSONFromDataT(data)
}

func NSJSONFromData(data: NSData) -> Promise<NSDictionary> {
    if data.isEqualToData(NSData(bytes: " ", length: 1)) {
        return Promise(value: NSDictionary())
    }
    return NSJSONFromDataT(data)
}

private func NSJSONFromDataT<T>(data: NSData) -> Promise<T> {
    var error:NSError?
    let json:AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options:nil, error:&error)

    if error != nil {
        return Promise(error: error!)
    } else if let cast = json as? T {
        return Promise(value: cast)
    } else {
        var info = NSMutableDictionary()
        info[NSLocalizedDescriptionKey] = "The server returned JSON in an unexpected arrangement"
        if let jo:AnyObject = json { info[PMKJSONErrorJSONObjectKey] = jo }
        let error = NSError(domain:PMKErrorDomain, code:PMKJSONError, userInfo:info)
        return Promise(error: error)
    }
}

private func fetchJSON<T>(request: NSURLRequest) -> Promise<T> {
    return fetch(request) { (fulfill, reject, data, _) in
        let result: Promise<T> = NSJSONFromDataT(data)
        if result.fulfilled {
            fulfill(result.value!)
        } else {
            reject(result.error!)
        }
    }
}


extension NSURLConnection {

    //TODO I couldn’t persuade Swift to process these generically hence the lack of DRY
    //TODO When you can DRY it out, add error handling for the NSURL?() initializer

    public class func GET(url:String) -> Promise<NSData> {
        return promise(NSURLRequest(URL:NSURL(string:url)!))
    }
    public class func GET(url:String) -> Promise<String> {
        return promise(NSURLRequest(URL:NSURL(string:url)!))
    }
    public class func GET(url:String) -> Promise<NSArray> {
        return promise(NSURLRequest(URL:NSURL(string:url)!))
    }
    public class func GET(url:String) -> Promise<NSDictionary> {
        return promise(NSURLRequest(URL:NSURL(string:url)!))
    }

    public class func GET(url:String, query:[String:String]) -> Promise<NSData> {
        return promise(OMGHTTPURLRQ.GET(url, query))
    }
    public class func GET(url:String, query:[String:String]) -> Promise<String> {
        return promise(OMGHTTPURLRQ.GET(url, query))
    }
    public class func GET(url:String, query:[String:String]) -> Promise<NSDictionary> {
        return promise(OMGHTTPURLRQ.GET(url, query))
    }
    public class func GET(url:String, query:[String:String]) -> Promise<NSArray> {
        return promise(OMGHTTPURLRQ.GET(url, query))
    }


    public class func POST(url:String, formData:[String:String]) -> Promise<NSData> {
        return promise(OMGHTTPURLRQ.POST(url, JSON: formData))
    }
    public class func POST(url:String, formData:[String:String]) -> Promise<String> {
        return promise(OMGHTTPURLRQ.POST(url, formData))
    }
    public class func POST(url:String, formData:[String:String]) -> Promise<NSArray> {
        return promise(OMGHTTPURLRQ.POST(url, formData))
    }
    public class func POST(url:String, formData:[String:String]) -> Promise<NSDictionary> {
        return promise(OMGHTTPURLRQ.POST(url, formData))
    }


    public class func POST(url:String, JSON json:[String:String]) -> Promise<NSData> {
        return promise(OMGHTTPURLRQ.POST(url, JSON: json))
    }
    public class func POST(url:String, JSON json:[String:String]) -> Promise<String> {
        return promise(OMGHTTPURLRQ.POST(url, JSON: json))
    }
    public class func POST(url:String, JSON json:[String:String]) -> Promise<NSArray> {
        return promise(OMGHTTPURLRQ.POST(url, JSON: json))
    }
    public class func POST(url:String, JSON json:[String:String]) -> Promise<NSDictionary> {
        return promise(OMGHTTPURLRQ.POST(url, JSON: json))
    }

    public class func POST(url:String, JSON json:[String:AnyObject]) -> Promise<NSDictionary> {
      return promise(OMGHTTPURLRQ.POST(url, JSON: json))
    }

    public class func POST(url:String, multipartFormData: OMGMultipartFormData) -> Promise<NSData> {
        return promise(OMGHTTPURLRQ.POST(url, multipartFormData))
    }
    public class func POST(url:String, multipartFormData: OMGMultipartFormData) -> Promise<String> {
        return promise(OMGHTTPURLRQ.POST(url, multipartFormData))
    }
    public class func POST(url:String, multipartFormData: OMGMultipartFormData) -> Promise<NSArray> {
        return promise(OMGHTTPURLRQ.POST(url, multipartFormData))
    }
    public class func POST(url:String, multipartFormData: OMGMultipartFormData) -> Promise<NSDictionary> {
        return promise(OMGHTTPURLRQ.POST(url, multipartFormData))
    }


    public class func promise(rq:NSURLRequest) -> Promise<NSData> {
        return fetch(rq) { (fulfill, _, data, _) in
            fulfill(data)
        }
    }

    public class func promise(rq: NSURLRequest) -> Promise<String> {
        return fetch(rq) { (fulfiller, rejecter, data, rsp) in
            let str = NSString(data: data, encoding:rsp.stringEncoding)
            if str != nil {
                fulfiller(str!)
            } else {
                let info = [NSLocalizedDescriptionKey: "The server response was not textual"]
                rejecter(NSError(domain:NSURLErrorDomain, code: NSURLErrorBadServerResponse, userInfo:info))
            }
        }
    }

    public class func promise(request: NSURLRequest) -> Promise<NSDictionary> {
        return fetchJSON(request)
    }

    public class func promise(request: NSURLRequest) -> Promise<NSArray> {
        return fetchJSON(request)
    }
}


#if os(IOS)
import UIKit.UIImage

extension NSURLConnection {

    public class func GET(url:String) -> Promise<UIImage> {
        return promise(NSURLRequest(URL:NSURL(string:url)!))
    }

    public class func GET(url:String, query:[String:String]) -> Promise<UIImage> {
        return promise(OMGHTTPURLRQ.GET(url, query))
    }

    public class func POST(url:String, formData:[String:String]) -> Promise<UIImage> {
        return promise(OMGHTTPURLRQ.POST(url, formData))
    }

    public class func POST(url:String, JSON json:[String:String]) -> Promise<UIImage> {
        return promise(OMGHTTPURLRQ.POST(url, JSON: json))
    }

    public class func POST(url:String, multipartFormData: OMGMultipartFormData) -> Promise<UIImage> {
        return promise(OMGHTTPURLRQ.POST(url, multipartFormData))
    }

    public class func promise(rq: NSURLRequest) -> Promise<UIImage> {
        return fetch(rq) { (fulfiller, rejecter, data, _) in
            assert(!NSThread.isMainThread())

            var img = UIImage(data: data) as UIImage!
            if img != nil {
                img = UIImage(CGImage:img.CGImage, scale:img.scale, orientation:img.imageOrientation)
                if img != nil {
                    return fulfiller(img)
                }
            }

            let info = [NSLocalizedDescriptionKey: "The server returned invalid image data"]
            rejecter(NSError(domain:NSURLErrorDomain, code:NSURLErrorBadServerResponse, userInfo:info))
        }
    }
}
#endif
