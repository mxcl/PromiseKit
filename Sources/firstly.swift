import Dispatch

/**
 Judicious use of `firstly` *may* make chains more readable.

 Compare:

     URLSession.shared.dataTask(url: url1).then {
         URLSession.shared.dataTask(url: url2)
     }.then {
         URLSession.shared.dataTask(url: url3)
     }

 With:

     firstly {
         URLSession.shared.dataTask(url: url1)
     }.then {
         URLSession.shared.dataTask(url: url2)
     }.then {
         URLSession.shared.dataTask(url: url3)
     }

 - Note: the block you pass excecutes immediately on the current thread/queue.
 */
public func firstly<U: Thenable>(execute body: () throws -> U) -> Promise<U.T> {
    do {
        let rp = Promise<U.T>(.pending)
        try body().pipe(to: rp.box.seal)
        return rp
    } catch {
        return Promise(error: error)
    }
}

/// - See: firstly()
public func firstly<T>(execute body: () -> Guarantee<T>) -> Guarantee<T> {
    return body()
}

/// - See: firstly()
/// - Note: the block you pass excecutes immediately on the specified thread/queue.
public func firstly<U: Thenable>(on: DispatchQueue, flags: DispatchWorkItemFlags? = nil, execute body: @escaping () throws -> U) -> Promise<U.T> {
    return Promise { seal in
        on.async(flags: flags) {
            firstly(execute: body).pipe(to: seal.resolve)
        }
    }
}

/// - See: firstly()
/// - Note: the block you pass excecutes immediately on the specified thread/queue.
public func firstly<T>(on: DispatchQueue, flags: DispatchWorkItemFlags? = nil, execute body: @escaping () -> Guarantee<T>) -> Guarantee<T> {
    return Guarantee { fulfilledResult in
        on.async(flags: flags) {
            firstly(execute: body).pipe(to: fulfilledResult)
        }
    }
}


private extension DispatchQueue {
    
    @inline(__always)
    func async(flags: DispatchWorkItemFlags?, _ body: @escaping() -> Void) {
        if let flags = flags {
            self.async(flags: flags, execute: body)
        } else {
            self.async(execute: body)
        }
    }
}
