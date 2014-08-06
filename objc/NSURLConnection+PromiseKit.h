#import <Foundation/NSDictionary.h>
#import <Foundation/NSURLConnection.h>
#import <Foundation/NSURLRequest.h>
#import <PromiseKit/fwd.h>

extern NSString const*const PMKURLErrorFailingURLResponse PMK_DEPRECATED("Use PMKURLErrorFailingURLResponseKey");
extern NSString const*const PMKURLErrorFailingData PMK_DEPRECATED("Use PMKURLErrorFailingDataKey");

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
