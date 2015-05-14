//TODO PMKFailingPromiseIndexKey

public func when<U, V>(pu: Promise<U>, pv: Promise<V>) -> Promise<(U, V)> {
    var u: U?
    var v: V?
    
    let (promise, fulfill, reject) = Promise<(U, V)>.defer()

    //FIXME copy n' pasted because Swift compiler crashes with a generic local function otherwise
    
    pu.pipe{ resolution in
        switch resolution {
        case .Rejected(let error):
            reject(error)
        case .Fulfilled(let value):
            u = (value as! U)
            if let uu = u, vv = v {
                fulfill(uu, vv)
            }
        }
    }
    pv.pipe{ resolution in
        switch resolution {
        case .Rejected(let error):
            reject(error)
        case .Fulfilled(let value):
            v = (value as! V)
            if let uu = u, vv = v {
                fulfill(uu, vv)
            }
        }
    }

    return promise
}

public func when<T>(promises: [Promise<T>]) -> Promise<[T]> {
    let (promise, fulfill, reject) = Promise<[T]>.defer()

    var x = promises.count
    for (index, promise) in enumerate(promises) {
        promise.pipe { resolution in
            switch resolution {
            case .Rejected(let error):
                reject(error)
            case .Fulfilled:
                if --x == 0 {
                    fulfill(promises.map{ $0.value! })
                }
            }
        }
    }
    
    return promise
}

public func when<T>(promises: Promise<T>...) -> Promise<[T]> {
    return when(promises)
}

public func when(promises: Promise<Void>...) -> Promise<Void> {
    let (promise, fulfill, reject) = Promise<Void>.defer()

    var x = promises.count
    for (index, promise) in enumerate(promises) {
        promise.pipe { resolution in
            switch resolution {
            case .Rejected(let error):
                reject(error)
            case .Fulfilled:
                if --x == 0 {
                    fulfill()
                }
            }
        }
    }

    return promise
}
