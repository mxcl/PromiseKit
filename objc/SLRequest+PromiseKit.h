//
//  Created by merowing on 09/05/2014.
//
//
//

#import <PromiseKit/fwd.h>
#import <Social/SLRequest.h>

extern NSString *const SLRequestPromiseKitErrorDomain PMK_DEPRECATED("Use PMKErrorDomain");
extern const NSInteger SLRequestPromiseKitServerStatusCodeErrorCode PMK_DEPRECATED("Use NSURLErrorBadServerResponse");
extern NSString *const SLRequestPromiseKitOriginalStatusCodeKey PMK_DEPRECATED("Use PMKURLErrorFailingURLResponseKey");
extern NSString *const SLRequestPromiseKitOriginalResponseDataKey PMK_DEPRECATED("Use PMKURLErrorFailingURLResponseKey");
extern NSString *const SLRequestPromiseKitResponseDataAsTextKey PMK_DEPRECATED("Use PMKURLErrorFailingStringKey");

/**
 To import the `SLRequest` category:

    pod "PromiseKit/SLRequest"

 Or you can import all categories on `Social`:

    pod "PromiseKit/Social"
*/
@interface SLRequest (PromiseKit)
/**
 Performs the request asynchronously.

 @return A promise that fulfills with three parameters:
 1) The response decoded as JSON.
 2) The `NSHTTPURLResponse`.
 3) The raw `NSData` response.

 @warning *Note* If PromiseKit determines the response is not JSON, the first
 parameter will instead be plain `NSData`.
*/
- (PMKPromise *)promise;

+ (PMKPromise *)promise:(SLRequest *)request PMK_DEPRECATED("Use `-promise`");
@end
