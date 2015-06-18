import Foundation
import PromiseKit
import OMGHTTPURLRQ

extension NSURLSession {
    class func GET(urlString: String) -> Promise<NSData> {
        return foo(try OMGHTTPURLRQ.GET(urlString, nil))
    }

    class func GET(urlString: String, query: [NSString: AnyObject]) -> Promise<NSData> {
        return foo(try OMGHTTPURLRQ.GET(urlString, query))
    }

    class func POST(urlString: String, formData: [String: AnyObject]) -> Promise<NSData> {
        return foo(try OMGHTTPURLRQ.POST(urlString, formData))
    }

    class func POST(urlString: String, multipartFormData: OMGMultipartFormData) -> Promise<NSData> {
        return foo(try OMGHTTPURLRQ.POST(urlString, multipartFormData))
    }

    class func PUT(urlString: String) -> Promise<NSData> {
        return foo(try OMGHTTPURLRQ.PUT(urlString, nil))
    }

    class func DELETE(urlString: String) -> Promise<NSData> {
        return foo(try OMGHTTPURLRQ.DELETE(urlString, nil))
    }

    private class func foo(@autoclosure body: () throws -> NSURLRequest) -> Promise<NSData> {
        do {
            let rq = try body()
            let conf = NSURLSessionConfiguration.defaultSessionConfiguration()
            let sess = NSURLSession(configuration: conf, delegate: nil, delegateQueue: PMKOperationQueue)
            return sess.promise(rq)
        } catch let error {
            return Promise(error as NSError)
        }
    }

    func promise(rq: NSURLRequest) -> Promise<NSData> {
        return Promise { (sealant: Sealant<NSData>) in
            let completion = { (data: NSData?, _: NSURLResponse?, error: NSError?) -> Void in
                sealant.resolve(data, error)
            }
            dataTaskWithRequest(rq, completionHandler: completion)
        }
    }
}

extension NSURLSession {
    class func GET(urlString: String) -> Promise<NSDictionary> {
        return foo(try OMGHTTPURLRQ.GET(urlString, nil))
    }

    class func GET(urlString: String, query: [NSString: AnyObject]) -> Promise<NSDictionary> {
        return foo(try OMGHTTPURLRQ.GET(urlString, query))
    }

    class func POST(urlString: String, formData: [String: AnyObject]) -> Promise<NSDictionary> {
        return foo(try OMGHTTPURLRQ.POST(urlString, formData))
    }

    class func POST(urlString: String, multipartFormData: OMGMultipartFormData) -> Promise<NSDictionary> {
        return foo(try OMGHTTPURLRQ.POST(urlString, multipartFormData))
    }

    class func PUT(urlString: String) -> Promise<NSDictionary> {
        return foo(try OMGHTTPURLRQ.PUT(urlString, nil))
    }

    class func DELETE(urlString: String) -> Promise<NSDictionary> {
        return foo(try OMGHTTPURLRQ.DELETE(urlString, nil))
    }

    private class func foo(@autoclosure body: () throws -> NSURLRequest) -> Promise<NSDictionary> {
        do {
            let rq = try body()
            let conf = NSURLSessionConfiguration.defaultSessionConfiguration()
            let sess = NSURLSession(configuration: conf, delegate: nil, delegateQueue: PMKOperationQueue)
            return sess.promise(rq)
        } catch let error {
            return Promise(error as NSError)
        }
    }

    func promise(rq: NSURLRequest) -> Promise<NSDictionary> {
        return promise(rq).then(on: waldo) { try NSJSONFromData($0) }
    }
}


#if os(iOS)

import UIKit.UIImage

extension NSURLSession {
    class func GET(urlString: String) -> Promise<UIImage> {
        return foo(try OMGHTTPURLRQ.GET(urlString, nil))
    }

    class func GET(urlString: String, query: [NSString: AnyObject]) -> Promise<UIImage> {
        return foo(try OMGHTTPURLRQ.GET(urlString, query))
    }

    private class func foo(@autoclosure body: () throws -> NSURLRequest) -> Promise<UIImage> {
        do {
            let rq = try body()
            let conf = NSURLSessionConfiguration.defaultSessionConfiguration()
            let sess = NSURLSession(configuration: conf, delegate: nil, delegateQueue: PMKOperationQueue)
            return sess.promise(rq)
        } catch let error {
            return Promise(error as NSError)
        }
    }

    func promise(rq: NSURLRequest) -> Promise<UIImage> {
        return promise(rq).then(on: waldo) { data -> UIImage in
            if let img = UIImage(data: data), cgimg = img.CGImage {
                return Promise(UIImage(CGImage: cgimg, scale: img.scale, orientation: img.imageOrientation))
            } else {
                let info = [NSLocalizedDescriptionKey: "The server returned invalid image data"]
                throw NSError(domain: NSURLErrorDomain, code: NSURLErrorBadServerResponse, userInfo: info)
            }
        }
    }
}

#endif
