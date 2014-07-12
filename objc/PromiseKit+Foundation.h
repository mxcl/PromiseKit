#import "PromiseKit/fwd.h"

#if PMK_MODULES
  @import Foundation.NSDictionary;
  @import Foundation.NSURLCache;
  @import Foundation.NSURLConnection;
  @import Foundation.NSURLRequest;
#else
  #import <Foundation/Foundation.h>
#endif

#define PMKURLErrorFailingURLResponseKey @"PMKURLErrorFailingURLResponseKey"
#define PMKURLErrorFailingDataKey @"PMKURLErrorFailingDataKey"

extern NSString const*const PMKURLErrorFailingURLResponse __attribute__((deprecated("Use PMKURLErrorFailingURLResponseKey")));
extern NSString const*const PMKURLErrorFailingData __attribute__((deprecated("Use PMKURLErrorFailingDataKey")));



@interface NSURLConnection (PromiseKit)

/**
 We depend on OMGHTTPURLRQ a NSURLRequest additions library that provides
 all the common REST style verbs and parameter encoders. Thus if you need
 eg. a multipartFormData POST, check out OMGHTTPURLRQ (which CocoaPods
 already pulled in for you).
*/
+ (PMKPromise *)GET:(id)stringFormatOrNSURL, ...;
+ (PMKPromise *)GET:(id)stringOrURL query:(NSDictionary *)parameters;
+ (PMKPromise *)POST:(id)stringOrURL formURLEncodedParameters:(NSDictionary *)parameters;
+ (PMKPromise *)PUT:(id)url formURLEncodedParameters:(NSDictionary *)params;
+ (PMKPromise *)DELETE:(id)url formURLEncodedParameters:(NSDictionary *)params;
+ (PMKPromise *)promise:(NSURLRequest *)rq;
@end



// ideally this would be from a pod, but I looked and all the pods imposed
// too much symbol overhead or used catgeories
NSString *NSDictionaryToURLQueryString(NSDictionary *parameters);


/**
 A sensible User-Agent string, that by default we set on your requests if you
 didn’t set your own.
*/
NSString *PMKUserAgent();
