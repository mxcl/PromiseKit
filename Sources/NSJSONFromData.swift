import Foundation

private func b0rkedEmptyRailsResponse() -> NSData {
    return NSData(bytes: " ", length: 1)
}

public func NSJSONFromData(data: NSData) -> Promise<NSArray> {
    if data == b0rkedEmptyRailsResponse() {
        return Promise(NSArray())
    } else {
        return NSJSONFromDataT(data)
    }
}

public func NSJSONFromData(data: NSData) -> Promise<NSDictionary> {
    if data == b0rkedEmptyRailsResponse() {
        return Promise(NSDictionary())
    } else {
        return NSJSONFromDataT(data)
    }
}

private func NSJSONFromDataT<T>(data: NSData) -> Promise<T> {
    do {
        let json: AnyObject? = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
        if let cast = json as? T {
            return Promise(cast)
        } else {
            var info = [NSObject: AnyObject]()
            info[NSLocalizedDescriptionKey] = "The server returned JSON in an unexpected arrangement"
            info[PMKJSONErrorJSONObjectKey] = json
            return Promise(NSError(domain: PMKErrorDomain, code: PMKJSONError, userInfo: info))
        }
    } catch let error {
        let debug = (error as NSError).userInfo["NSDebugDescription"] as? String
        let description = "The server’s JSON response could not be decoded. (\(debug))"
        return Promise(NSError(domain: PMKErrorDomain, code: PMKJSONError, userInfo: [
            NSLocalizedDescriptionKey: description,
            NSUnderlyingErrorKey: error as NSError
        ]))
    }
}
