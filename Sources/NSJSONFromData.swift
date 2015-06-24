import Foundation

private func b0rkedEmptyRailsResponse() -> NSData {
    return NSData(bytes: " ", length: 1)
}

public func NSJSONFromData(data: NSData) throws -> NSArray {
    if data == b0rkedEmptyRailsResponse() {
        return NSArray()
    } else {
        return try NSJSONFromDataT(data)
    }
}

public func NSJSONFromData(data: NSData) throws -> NSDictionary {
    if data == b0rkedEmptyRailsResponse() {
        return NSDictionary()
    } else {
        return try NSJSONFromDataT(data)
    }
}

private func NSJSONFromDataT<T>(data: NSData) throws -> T {
    let json: AnyObject
    do {
        json = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
    } catch (let errorType) {
        let error = errorType as NSError
        let debug = error.userInfo["NSDebugDescription"] as! String
        let description = "The server’s JSON response could not be decoded. (\(debug))"
        throw NSError(domain: PMKErrorDomain, code: PMKJSONError, userInfo: [
            NSLocalizedDescriptionKey: "There was an error decoding the server’s JSON response.",
            NSUnderlyingErrorKey: error, NSLocalizedDescriptionKey: description])
    }

    if let cast = json as? T {
        return cast
    } else {
        var info = [NSObject: AnyObject]()
        info[NSLocalizedDescriptionKey] = "The server returned JSON in an unexpected arrangement"
        info[PMKJSONErrorJSONObjectKey] = json
        throw NSError(domain: PMKErrorDomain, code: PMKJSONError, userInfo: info)
    }
}
