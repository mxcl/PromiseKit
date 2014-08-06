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

@interface SLRequest (PromiseKit)
/**
 `thens` the decoded JSON, the NSHTTPURLReponse and finally the original `NSData`

 If the response is not JSON, then the first parameter will be the `NSData`, ie. the same as the third.
*/
- (PMKPromise *)promise;

+ (PMKPromise *)promise:(SLRequest *)request PMK_DEPRECATED("Use `-promise`");
@end
