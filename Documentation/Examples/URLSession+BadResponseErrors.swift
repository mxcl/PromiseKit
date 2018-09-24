Promise(.pending) { seal in
    URLSession.shared.dataTask(with: rq, completionHandler: { data, rsp, error in
        if let data = data {
            seal.fulfill(data)
        } else if let error = error {
            if case URLError.badServerResponse = error, let rsp = rsp as? HTTPURLResponse {
                seal.reject(Error.badResponse(rsp.statusCode))
            } else {
                seal.reject(error)
            }
        } else {
            seal.reject(PMKError.invalidCallingConvention)
        }
    })
}

enum Error: Swift.Error {
    case badUrl
    case badResponse(Int)
}
