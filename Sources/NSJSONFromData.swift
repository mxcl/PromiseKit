import Foundation

public enum JSONError: ErrorType {
    case UnexpectedRootNode(AnyObject)
}

private func b0rkedEmptyRailsResponse() -> NSData {
    return NSData(bytes: " ", length: 1)
}

public func NSJSONFromData(data: NSData) throws -> NSArray {
    if data == b0rkedEmptyRailsResponse() {
        return NSArray()
    } else {
        let json = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        guard let dict = json as? NSArray else { throw JSONError.UnexpectedRootNode(json) }
        return dict
    }
}

public func NSJSONFromData(data: NSData) throws -> NSDictionary {
    if data == b0rkedEmptyRailsResponse() {
        return NSDictionary()
    } else {
        let json = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        guard let dict = json as? NSDictionary else { throw JSONError.UnexpectedRootNode(json) }
        return dict
    }
}
