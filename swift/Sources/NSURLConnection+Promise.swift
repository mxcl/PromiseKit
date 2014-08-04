import Foundation
import UIKit

let PMKOperationQueue = NSOperationQueue()


func _parse<T>(data:NSData, fulfiller:(T) -> Void, rejecter:(NSError) -> Void) {
    assert(!NSThread.isMainThread())

    var error:NSError?
    let json:AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options:nil, error:&error)

    if error != nil {
        rejecter(error!)
    } else if let cast = json as? T {
        fulfiller(cast)
    } else {
        var info:Dictionary = [:]
        info[NSLocalizedDescriptionKey] = "The server returned JSON in an unexpected arrangement"
        if let jo:AnyObject = json { info[PMKJSONErrorJSONObjectKey] = jo }
        rejecter(NSError(domain:PMKErrorDomain, code:PMKJSONError, userInfo:info))
    }
}

func PMKUserAgent() -> String {
    struct Static {
        static var instance: String? = nil
        static var token: dispatch_once_t = 0
    }
    dispatch_once(&Static.token, {
        let info = NSBundle.mainBundle().infoDictionary
        let name:AnyObject? = info[kCFBundleIdentifierKey]
        let appv:AnyObject? = info[kCFBundleVersionKey]
        let scale = UInt(UIScreen.mainScreen().scale)
        let model = UIDevice.currentDevice().model
        let sysv = UIDevice.currentDevice().systemVersion
        Static.instance = "\(name)/\(appv) (\(model); iOS \(sysv); Scale/\(scale).0"
    })
    return Static.instance!
}


func fetch<T>(var request: NSURLRequest, body: ((T) -> Void, (NSError) -> Void, NSData) -> Void) -> Promise<T> {

    if !request.valueForHTTPHeaderField("User-Agent") {
        let rq = request.mutableCopy() as NSMutableURLRequest
        rq.setValue(PMKUserAgent(), forHTTPHeaderField:"User-Agent")
        request = rq
    }

    return Promise<T> { (fulfiller, rejunker) in
        NSURLConnection.sendAsynchronousRequest(request, queue:PMKOperationQueue) { (rsp, data, err) in

            assert(!NSThread.isMainThread())

            //TODO handle non 2xx responses
            //TODO in the event of a non 2xx rsp, try to parse JSON out of the response anyway

            func rejecter(error:NSError) {
                let info = NSMutableDictionary(dictionary: error.userInfo)
                if let s = request.URL.absoluteString { info[NSURLErrorFailingURLStringErrorKey] = s }
                info[NSURLErrorFailingURLErrorKey] = request.URL
                if data { info[PMKURLErrorFailingDataKey] = data! }
                if rsp { info[PMKURLErrorFailingURLResponseKey] = rsp! }
                rejunker(NSError(domain:error.domain, code:error.code, userInfo:info))
            }

            if err {
                rejecter(err)
            } else {
                body(fulfiller, rejecter, data!)
            }
        }
    }
}


extension NSURLConnection {

    // Swift generics are not 100% capable yet, hence the repetition

    public class func GET(url:String) -> Promise<NSData> {
        let rq = NSURLRequest(URL:NSURL(string:url))
        return promise(rq)
    }
    public class func GET(url:String) -> Promise<String> {
        let rq = NSURLRequest(URL:NSURL(string:url))
        return promise(rq)
    }
    public class func GET(url:String) -> Promise<UIImage> {
        let rq = NSURLRequest(URL:NSURL(string:url))
        return promise(rq)
    }
    public class func GET(url:String) -> Promise<NSArray> {
        let rq = NSURLRequest(URL:NSURL(string:url))
        return promise(rq)
    }
    public class func GET(url:String) -> Promise<NSDictionary> {
        return promise(NSURLRequest(URL:NSURL(string:url)))
    }
    public class func GET(url:String, query:Dictionary<String, String>) -> Promise<NSDictionary> {
        return promise(NSURLRequest(URL:NSURL(string:url + PMKDictionaryToURLQueryString(query))))
    }
    public class func GET(url:String, query:Dictionary<String, String>) -> Promise<NSArray> {
        return promise(NSURLRequest(URL:NSURL(string:url + PMKDictionaryToURLQueryString(query))))
    }
    
    public class func promise(rq:NSURLRequest) -> Promise<NSData> {
        return fetch(rq) { (fulfiller, _, data) in
            fulfiller(data)
        }
    }

    public class func promise(rq:NSURLRequest) -> Promise<String> {
        return fetch(rq) { (fulfiller, rejecter, data) in
            let str:String? = NSString(data: data, encoding: NSUTF8StringEncoding)
            if str != nil {
                fulfiller(str!)
            } else {
                let info = [NSLocalizedDescriptionKey: "The server returned repsonse was not textual"]
                rejecter(NSError(domain:NSURLErrorDomain, code: NSURLErrorBadServerResponse, userInfo:info))
            }
        }
    }

    //TODO DRY these out
    //NOTE I did DRY them out, but then something went wrong with
    // generics and the cast stopped working in the generic function
    //TODO Rather than AnyObject have some kind of something so
    // that only JSON object types work, also ideally I should be
    // about to specify eg String[] or [String:Array] etc.

    public class func promise(request:NSURLRequest) -> Promise<NSDictionary> {
        return fetch(request) { (fulfiller, rejecter, data) in
            var error:NSError?
            let json:AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options:nil, error:&error)

            if error != nil {
                rejecter(error!)
            } else if let cast = json as? Dictionary<String, String> {
                println(json)
                println(cast)
                fulfiller(cast)
            } else {
                var info:Dictionary = [:]
                info[NSLocalizedDescriptionKey] = "The server returned JSON in an unexpected arrangement"
                if let jo:AnyObject = json { info[PMKJSONErrorJSONObjectKey] = jo }
                rejecter(NSError(domain:PMKErrorDomain, code:PMKJSONError, userInfo:info))
            }

        }
    }

    public class func promise(request:NSURLRequest) -> Promise<NSArray> {
        return fetch(request) { (fulfiller, rejecter, data) in
            var error:NSError?
            let json:AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options:nil, error:&error)

            if error != nil {
                rejecter(error!)
            } else if let cast = json as? NSArray {
                fulfiller(cast)
            } else {
                var info:Dictionary = [:]
                info[NSLocalizedDescriptionKey] = "The server returned JSON in an unexpected arrangement"
                if let jo:AnyObject = json { info[PMKJSONErrorJSONObjectKey] = jo }
                rejecter(NSError(domain:PMKErrorDomain, code:PMKJSONError, userInfo:info))
            }

        }
    }

    public class func promise(rq:NSURLRequest) -> Promise<UIImage> {
        return fetch(rq) { (fulfiller, rejecter, data) in
            var img:UIImage? = UIImage(data:data)
            if img != nil {
                img = UIImage(CGImage:img!.CGImage, scale:img!.scale, orientation:img!.imageOrientation)
                if img != nil {
                    return fulfiller(img!)
                }
            }

            let info = [NSLocalizedDescriptionKey: "The server returned invalid image data"]
            rejecter(NSError(domain:NSURLErrorDomain, code:NSURLErrorBadServerResponse, userInfo:info))

            assert(!NSThread.isMainThread())
        }
    }
}
