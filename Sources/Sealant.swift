import Foundation.NSError

public class Sealant<T> {
    let handler: (Resolution) -> ()

    init(body: (Resolution) -> Void) {
        handler = body
    }

    /** internal because it is dangerous */
    func __resolve(obj: AnyObject) {
        switch obj {
        case is NSError:
            resolve(obj as! NSError)
        default:
            handler(.Fulfilled(obj))
        }
    }

    public func resolve(value: T) {
        handler(.Fulfilled(value))
    }

    public func resolve(error: NSError!) {
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
    public func resolve(obj: T!, var _ error: NSError!) {
        if obj != nil {
            handler(.Fulfilled(obj))
        } else if error != nil {
            resolve(error)
        } else {
            //FIXME couldn't get the constants from the umbrella header :(
            error = NSError(domain: PMKErrorDomain, code: /*PMKUnexpectedError*/ 1, userInfo: nil)
            resolve(error)
        }
    }
    
    public func resolve(obj: T, _ error: NSError!) {
        if error == nil {
            handler(.Fulfilled(obj))
        } else  {
            resolve(error)
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
