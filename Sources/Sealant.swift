import Foundation.NSError


public enum SealantError: ErrorType {
    /**
      The closure with form (T?, ErrorType?) was called with (nil, nil)
      This is an invalid calling convention.
    */
    case DoubleOhSux0r
}


public class Sealant<T> {
    private let handler: (Resolution<T>) -> ()

    init(body: (Resolution<T>) -> Void) {
        handler = body
    }

    public func resolve(value: T) {
        handler(.Fulfilled(value))
    }

    public func resolve(error: ErrorType) {
        unconsume(error)
        handler(.Rejected(error))
    }

    /**
     Makes wrapping (typical) asynchronous patterns easy.

     For example, here we wrap an `MKLocalSearch`:

         func search() -> Promise<MKLocalSearchResponse> {
             return Promise { sealant in
                 MKLocalSearch(request: …).startWithCompletionHandler(sealant.resolve)
             }
         }

     To get this to work you often have to help the compiler by specifiying
     the type. In future versions of Swift, this should become unecessary.
    */
    public func resolve(obj: T?, _ error: NSError?) {
        if let obj = obj {
            handler(.Fulfilled(obj))
        } else if let error = error {
            resolve(error)
        } else {
            resolve(SealantError.DoubleOhSux0r)
        }
    }

    public func resolve(obj: T, _ error: NSError?) {
        if let error = error {
            resolve(error)
        } else {
            handler(.Fulfilled(obj))
        }
    }

    /**
     Provided for APIs that *still* return [AnyObject] because they suck.
     FIXME fails
    */
//    public func convert(objects: [AnyObject]!, _ error: NSError!) {
//        if error != nil {
//            resolve(error)
//        } else {
//            handler(.Fulfilled(objects))
//        }
//    }

    /**
     For the case where T is Void. If it isn’t stuff will crash at some point.
     FIXME crashes when T is Void and .Fulfilled contains Void. Fucking sigh.
    */
//    public func ignore<U>(obj: U, _ error: NSError!) {
//        if error == nil {
//            handler(.Fulfilled(T))
//        } else {
//            resolve(error)
//        }
//    }
}
