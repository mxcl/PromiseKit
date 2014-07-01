//
//  Created by merowing on 09/05/2014.
//
//
//

#import "PromiseKit/fwd.h"

#if PMK_iOS6_ISH

#if PMK_MODULES
  @import Social.SLRequest;
#else
  #import <Social/Social.h>
#endif

extern NSString *const SLRequestPromiseKitErrorDomain;
extern const NSInteger SLRequestPromiseKitServerStatusCodeErrorCode;
extern NSString *const SLRequestPromiseKitOriginalStatusCodeKey;
extern NSString *const SLRequestPromiseKitOriginalResponseDataKey;
extern NSString *const SLRequestPromiseKitResponseDataAsTextKey;

@interface SLRequest (PromiseKit)
/**
 `thens` the decoded JSON, the NSHTTPURLReponse and finally the original `NSData`

 If the response is not JSON, then the first parameter will be the `NSData`, ie. the same as the third.
*/
- (PMKPromise *)promise;

+ (PMKPromise *)promise:(SLRequest *)request __attribute__((deprecated("Use `-promise`")));;
@end

#endif
