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
    var error: NSError?
    let json: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options:nil, error:&error)

    if let cast = json as? T {
        return Promise(cast)
    } else if let error = error {
        // NSJSONSerialization gives awful errors, so we wrap it
        let debug = error.userInfo!["NSDebugDescription"] as? String
        let description = "The server’s JSON response could not be decoded. (\(debug))"
        return Promise(NSError(domain: PMKErrorDomain, code: PMKJSONError, userInfo: [
            NSLocalizedDescriptionKey: "There was an error decoding the server’s JSON response.",
            NSUnderlyingErrorKey: error
        ]))
    } else {
        var info = [NSObject: AnyObject]()
        info[NSLocalizedDescriptionKey] = "The server returned JSON in an unexpected arrangement"
        info[PMKJSONErrorJSONObjectKey] = json
        return Promise(NSError(domain: PMKErrorDomain, code: PMKJSONError, userInfo: info))
    }
}
