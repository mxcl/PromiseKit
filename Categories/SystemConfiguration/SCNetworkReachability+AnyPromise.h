#import <PromiseKit/AnyPromise.h>

/**
 Resolves as soon as the Internet is accessible. If it is already
 accessible, resolves immediately.

 To import `SCNetworkReachability`:

    use_frameworks!
    pod "PromiseKit/SystemConfiguration"

 And then in your sources:

    @import PromiseKit;

 @return A void promise that fulfills when the Internet becomes accessible.
*/
AnyPromise *SCNetworkReachability();
