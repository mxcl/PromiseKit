import Foundation

func NSJSONFromData(data: NSData) -> Promise<NSArray> {
    // work around ever-so-common Rails issue: https://github.com/rails/rails/issues/1742
    if data.isEqualToData(NSData(bytes: " ", length: 1)) {
        return Promise(value: NSArray())  // couldn’t do T() in generic function
    }
    return NSJSONFromDataT(data)
}

func NSJSONFromData(data: NSData) -> Promise<NSDictionary> {
    if data.isEqualToData(NSData(bytes: " ", length: 1)) {
        return Promise(value: NSDictionary())
    }
    return NSJSONFromDataT(data)
}

private func NSJSONFromDataT<T>(data: NSData) -> Promise<T> {
    var error:NSError?
    let json:AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options:nil, error:&error)

    if error != nil {
        return Promise(error: error!)
    } else if let cast = json as? T {
        return Promise(value: cast)
    } else {
        var info = NSMutableDictionary()
        info[NSLocalizedDescriptionKey] = "The server returned JSON in an unexpected arrangement"
        if let jo:AnyObject = json { info[PMKJSONErrorJSONObjectKey] = jo }
        let error = NSError(domain:PMKErrorDomain, code:PMKJSONError, userInfo:info)
        return Promise(error: error)
    }
}
