import Foundation
import OMGHTTPURLRQ
#if !COCOAPODS
import PromiseKit
#endif

//TODO cancellation


/**
 We provide convenience categories for the `sharedSession`, or 
 an instance method `promise`. If you need more complicated behavior
 we recommend wrapping that usage in a Promise initializer.
*/
extension NSURLSession {
    public class func GET(urlString: String) -> Promise<NSData> {
        return start(try OMGHTTPURLRQ.GET(urlString, nil))
    }

    public class func GET(urlString: String, query: [NSString: AnyObject]) -> Promise<NSData> {
        return start(try OMGHTTPURLRQ.GET(urlString, query))
    }

    public class func POST(urlString: String, formData: [String: AnyObject]) -> Promise<NSData> {
        return start(try OMGHTTPURLRQ.POST(urlString, formData))
    }

    public class func POST(urlString: String, multipartFormData: OMGMultipartFormData) -> Promise<NSData> {
        return start(try OMGHTTPURLRQ.POST(urlString, multipartFormData))
    }

    public class func PUT(urlString: String) -> Promise<NSData> {
        return start(try OMGHTTPURLRQ.PUT(urlString, nil))
    }

    public class func DELETE(urlString: String) -> Promise<NSData> {
        return start(try OMGHTTPURLRQ.DELETE(urlString, nil))
    }

    private class func start(@autoclosure body: () throws -> NSURLRequest) -> Promise<NSData> {
        do {
            return NSURLSession.sharedSession().promise(try body())
        } catch {
            return Promise(error: error)
        }
    }

    public func promise(rq: NSURLRequest) -> Promise<NSData> {
        return Promise { (resolve: (NSData?, NSError?) -> Void) in
            let completion = { (data: NSData?, _: NSURLResponse?, error: NSError?) -> Void in
                //TODO add more error info to error
                resolve(data, error)
            }
            dataTaskWithRequest(rq, completionHandler: completion).resume()
        }
    }

    public enum Error: ErrorType {
        case InvalidImage(NSData)
    }
}

extension NSURLSession {
    public class func GET(urlString: String) -> Promise<NSDictionary> {
        return start(try OMGHTTPURLRQ.GET(urlString, nil))
    }

    public class func GET(urlString: String, query: [NSString: AnyObject]) -> Promise<NSDictionary> {
        return start(try OMGHTTPURLRQ.GET(urlString, query))
    }

    public class func POST(urlString: String, formData: [String: AnyObject]) -> Promise<NSDictionary> {
        return start(try OMGHTTPURLRQ.POST(urlString, formData))
    }

    public class func POST(urlString: String, multipartFormData: OMGMultipartFormData) -> Promise<NSDictionary> {
        return start(try OMGHTTPURLRQ.POST(urlString, multipartFormData))
    }

    public class func PUT(urlString: String) -> Promise<NSDictionary> {
        return start(try OMGHTTPURLRQ.PUT(urlString, nil))
    }

    public class func DELETE(urlString: String) -> Promise<NSDictionary> {
        return start(try OMGHTTPURLRQ.DELETE(urlString, nil))
    }

    private class func start(@autoclosure body: () throws -> NSURLRequest) -> Promise<NSDictionary> {
        do {
            return NSURLSession.sharedSession().promise(try body())
        } catch {
            return Promise(error: error)
        }
    }

    public func promise(rq: NSURLRequest) -> Promise<NSDictionary> {
        return promise(rq).then(on: waldo) { try NSJSONFromData($0) }
    }
}


#if os(iOS)

import UIKit.UIImage

extension NSURLSession {
    public class func GET(urlString: String) -> Promise<UIImage> {
        return start(try OMGHTTPURLRQ.GET(urlString, nil))
    }

    public class func GET(urlString: String, query: [NSString: AnyObject]) -> Promise<UIImage> {
        return start(try OMGHTTPURLRQ.GET(urlString, query))
    }

    private class func start(@autoclosure body: () throws -> NSURLRequest) -> Promise<UIImage> {
        do {
            return NSURLSession.sharedSession().promise(try body())
        } catch let error {
            return Promise(error: error)
        }
    }

    public func promise(rq: NSURLRequest) -> Promise<UIImage> {
        return promise(rq).then(on: waldo) { (data: NSData) -> UIImage in
            guard let img = UIImage(data: data), cgimg = img.CGImage else {
                throw Error.InvalidImage(data)
            }
            return UIImage(CGImage: cgimg, scale: img.scale, orientation: img.imageOrientation)
        }
    }
}

#endif
