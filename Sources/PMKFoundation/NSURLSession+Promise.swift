import Foundation
#if !PMKCocoaPods
import PromiseKit
#endif
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/**
 To import the `NSURLSession` category:

    use_frameworks!
    pod "PromiseKit/Foundation"

 Or `NSURLSession` is one of the categories imported by the umbrella pod:

    use_frameworks!
    pod "PromiseKit"

 And then in your sources:

    import PromiseKit
*/
extension URLSession {
    /**
     Example usage:

         firstly {
             URLSession.shared.dataTask(.promise, with: rq)
         }.compactMap { data, _ in
             try JSONSerialization.jsonObject(with: data) as? [String: Any]
         }.then { json in
             //…
         }

     We recommend the use of [OMGHTTPURLRQ] which allows you to construct correct REST requests:

         firstly {
             let rq = OMGHTTPURLRQ.POST(url, json: parameters)
             URLSession.shared.dataTask(.promise, with: rq)
         }.then { data, urlResponse in
             //…
         }

     We provide a convenience initializer for `String` specifically for this promise:
     
         firstly {
             URLSession.shared.dataTask(.promise, with: rq)
         }.compactMap(String.init).then { string in
             // decoded per the string encoding specified by the server
         }.then { string in
             print("response: string")
         }
     
     Other common types can be easily decoded using compactMap also:
     
         firstly {
             URLSession.shared.dataTask(.promise, with: rq)
         }.compactMap {
             UIImage(data: $0)
         }.then {
             self.imageView.image = $0
         }

     Though if you do decode the image this way, we recommend inflating it on a background thread
     first as this will improve main thread performance when rendering the image:
     
         firstly {
             URLSession.shared.dataTask(.promise, with: rq)
         }.compactMap(on: QoS.userInitiated) { data, _ in
             guard let img = UIImage(data: data) else { return nil }
             _ = cgImage?.dataProvider?.data
             return img
         }.then {
             self.imageView.image = $0
         }

     - Parameter convertible: A URL or URLRequest.
     - Returns: A promise that represents the URL request.
     - SeeAlso: [OMGHTTPURLRQ]
     - Remark: We deliberately don’t provide a `URLRequestConvertible` for `String` because in our experience, you should be explicit with this error path to make good apps.
     
     [OMGHTTPURLRQ]: https://github.com/mxcl/OMGHTTPURLRQ
     */
    public func dataTask(_: PMKNamespacer, with convertible: URLRequestConvertible) -> Promise<(data: Data, response: URLResponse)> {
        return Promise { dataTask(with: convertible.pmkRequest, completionHandler: adapter($0)).resume() }
    }

    public func uploadTask(_: PMKNamespacer, with convertible: URLRequestConvertible, from data: Data) -> Promise<(data: Data, response: URLResponse)> {
        return Promise { uploadTask(with: convertible.pmkRequest, from: data, completionHandler: adapter($0)).resume() }
    }

    public func uploadTask(_: PMKNamespacer, with convertible: URLRequestConvertible, fromFile file: URL) -> Promise<(data: Data, response: URLResponse)> {
        return Promise { uploadTask(with: convertible.pmkRequest, fromFile: file, completionHandler: adapter($0)).resume() }
    }

    /// - Remark: we force a `to` parameter because Apple deletes the downloaded file immediately after the underyling completion handler returns.
    /// - Note: we do not create the destination directory for you, because we move the file with FileManager.moveItem which changes it behavior depending on the directory status of the URL you provide. So create your own directory first!
    public func downloadTask(_: PMKNamespacer, with convertible: URLRequestConvertible, to saveLocation: URL) -> Promise<(saveLocation: URL, response: URLResponse)> {
        return Promise { seal in
            downloadTask(with: convertible.pmkRequest, completionHandler: { tmp, rsp, err in
                if let error = err {
                    seal.reject(error)
                } else if let rsp = rsp, let tmp = tmp {
                    do {
                        try FileManager.default.moveItem(at: tmp, to: saveLocation)
                        seal.fulfill((saveLocation, rsp))
                    } catch {
                        seal.reject(error)
                    }
                } else {
                    seal.reject(PMKError.invalidCallingConvention)
                }
            }).resume()
        }
    }
}


public protocol URLRequestConvertible {
    var pmkRequest: URLRequest { get }
}
extension URLRequest: URLRequestConvertible {
    public var pmkRequest: URLRequest { return self }
}
extension URL: URLRequestConvertible {
    public var pmkRequest: URLRequest { return URLRequest(url: self) }
}


#if !os(Linux) && !os(Windows)
public extension String {
    /**
      - Remark: useful when converting a `URLSession` response into a `String`

            firstly {
                URLSession.shared.dataTask(.promise, with: rq)
            }.map(String.init).done {
                print($0)
            }
     */
    init?(data: Data, urlResponse: URLResponse) {
        guard let str = String(bytes: data, encoding: urlResponse.stringEncoding ?? .utf8) else {
            return nil
        }
        self.init(str)
    }
}

private extension URLResponse {
    var stringEncoding: String.Encoding? {
        guard let encodingName = textEncodingName else { return nil }
        let encoding = CFStringConvertIANACharSetNameToEncoding(encodingName as CFString)
        guard encoding != kCFStringEncodingInvalidId else { return nil }
        return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(encoding))
    }
}
#endif

private func adapter<T, U>(_ seal: Resolver<(data: T, response: U)>) -> (T?, U?, Error?) -> Void {
    return { t, u, e in
        if let t = t, let u = u {
            seal.fulfill((t, u))
        } else if let e = e {
            seal.reject(e)
        } else {
            seal.reject(PMKError.invalidCallingConvention)
        }
    }
}


public enum PMKHTTPError: Error, LocalizedError, CustomStringConvertible {
    case badStatusCode(Int, Data, HTTPURLResponse)

    public var errorDescription: String? {
        func url(_ rsp: URLResponse) -> String {
            return rsp.url?.absoluteString ?? "nil"
        }
        switch self {
        case .badStatusCode(401, _, let response):
            return "Unauthorized (\(url(response))"
        case .badStatusCode(let code, _, let response):
            return "Invalid HTTP response (\(code)) for \(url(response))."
        }
    }

    public func decodeResponse<T: Decodable>(_ t: T.Type, decoder: JSONDecoder = JSONDecoder()) -> T? {
        switch self {
        case .badStatusCode(_, let data, _):
            return try? decoder.decode(t, from: data)
        }
    }

    //TODO rename responseJSON
    public var jsonDictionary: Any? {
        switch self {
        case .badStatusCode(_, let data, _):
            return try? JSONSerialization.jsonObject(with: data)
        }
    }

    var responseBodyString: String? {
        switch self {
        case .badStatusCode(_, let data, _):
            return String(data: data, encoding: .utf8)
        }
    }

    public var failureReason: String? {
        return responseBodyString
    }

    public var description: String {
        switch self {
        case .badStatusCode(let code, let data, let response):
            var dict: [String: Any] = [
                "Status Code": code,
                "Body": String(data: data, encoding: .utf8) ?? "\(data.count) bytes"
            ]
            dict["URL"] = response.url
            dict["Headers"] = response.allHeaderFields
            return "<NSHTTPResponse> \(NSDictionary(dictionary: dict))" // as NSDictionary makes the output look like NSHTTPURLResponse looks
        }
    }
}

public extension Promise where T == (data: Data, response: URLResponse) {
    func validate() -> Promise<T> {
        return map {
            guard let response = $0.response as? HTTPURLResponse else { return $0 }
            switch response.statusCode {
            case 200..<300:
                return $0
            case let code:
                throw PMKHTTPError.badStatusCode(code, $0.data, response)
            }
        }
    }
}
