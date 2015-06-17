import Foundation
import PromiseKit
import OMGHTTPURLRQ

extension NSURLSession {
    class func GET(urlString: String) -> Promise<NSData> {
        return Promise { (sealant: Sealant<NSData>) -> Void in
            guard let url = NSURL(string: urlString) else { sealant.reject("Bad URL"); return }

            let rq = NSURLRequest(URL: url)
            let conf = NSURLSessionConfiguration.defaultSessionConfiguration()
            let sess = NSURLSession(configuration: conf, delegate: nil, delegateQueue: PMKOperationQueue)
            sess.dataTaskWithRequest(rq) { data, response, error in
                sealant.resolve(data, error)
            }
        }
    }

    class func POST(urlString: String, parameters: [String: AnyObject]) -> Promise<NSData> {
        return Promise { (sealant: Sealant<NSData>) -> Void in
            let rq = OMGHTTPURLRQ.POST(urlString, parameters)
            let conf = NSURLSessionConfiguration.defaultSessionConfiguration()
            let sess = NSURLSession(configuration: conf, delegate: nil, delegateQueue: PMKOperationQueue)
            sess.dataTaskWithRequest(rq) { data, response, error in
                sealant.resolve(data, error)
            }
        }
    }
}
