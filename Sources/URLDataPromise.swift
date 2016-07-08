import Foundation

public enum Encoding {
    case json(JSONSerialization.ReadingOptions)
}

public class URLDataPromise: Promise<Data> {
    public func asDataAndResponse() -> Promise<(Data, Foundation.URLResponse)> {
        return then(on: zalgo) { ($0, self.URLResponse) }
    }

    public func asString() -> Promise<String> {
        return then(on: waldo) { data -> String in
            guard let str = String(bytes: data, encoding: self.URLResponse.stringEncoding ?? .utf8) else {
                throw URLError.stringEncoding(self.URLRequest, data, self.URLResponse)
            }
            return str
        }
    }

    public func asArray(_ encoding: Encoding = .json(.allowFragments)) -> Promise<NSArray> {
        return then(on: waldo) { data -> NSArray in
            switch encoding {
            case .json(let options):
                guard !data.b0rkedEmptyRailsResponse else { return NSArray() }
                let json = try JSONSerialization.jsonObject(with: data, options: options)
                guard let array = json as? NSArray else { throw JSONError.unexpectedRootNode(json) }
                return array
            }
        }
    }

    public func asDictionary(_ encoding: Encoding = .json(.allowFragments)) -> Promise<NSDictionary> {
        return then(on: waldo) { data -> NSDictionary in
            switch encoding {
            case .json(let options):
                guard !data.b0rkedEmptyRailsResponse else { return NSDictionary() }
                let json = try JSONSerialization.jsonObject(with: data, options: options)
                guard let dict = json as? NSDictionary else { throw JSONError.unexpectedRootNode(json) }
                return dict
            }
        }
    }

    private override init(resolvers: @noescape (fulfill: (Data) -> Void, reject: (ErrorProtocol) -> Void) throws -> Void) {
        super.init(resolvers: resolvers)
    }

    private var URLRequest: Foundation.URLRequest!
    private var URLResponse: Foundation.URLResponse!

    public class func go(_ request: Foundation.URLRequest, body: @noescape ((Data?, Foundation.URLResponse?, NSError?) -> Void) -> Void) -> URLDataPromise {
        var promise: URLDataPromise!
        promise = URLDataPromise { fulfill, reject in
            body { data, rsp, error in
                promise.URLRequest = request
                promise.URLResponse = rsp

                if let error = error {
                    reject(URLError.underlyingCocoaError(request, data, rsp, error))
                } else if let data = data, let rsp = rsp as? HTTPURLResponse, rsp.statusCode >= 200, rsp.statusCode < 300 {
                    fulfill(data)
                } else if let data = data, !(rsp is HTTPURLResponse) {
                    fulfill(data)
                } else {
                    reject(URLError.badResponse(request, data, rsp))
                }
            }
        }
        return promise
    }
}

#if os(iOS)
    import UIKit.UIImage

    extension URLDataPromise {
        public func asImage() -> Promise<UIImage> {
            return then(on: waldo) { data -> UIImage in
                guard let img = UIImage(data: data), let cgimg = img.cgImage else {
                    throw URLError.invalidImageData(self.URLRequest, data)
                }
                return UIImage(cgImage: cgimg, scale: img.scale, orientation: img.imageOrientation)
            }
        }
    }
#endif

extension URLResponse {
    private var stringEncoding: String.Encoding? {
        guard let encodingName = textEncodingName else { return nil }
        let encoding = CFStringConvertIANACharSetNameToEncoding(encodingName)
        guard encoding != kCFStringEncodingInvalidId else { return nil }
        return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(encoding))
    }
}

extension Data {
    private var b0rkedEmptyRailsResponse: Bool {
        return count == 1 && withUnsafeBytes{ $0[0] == " " }
    }
}
