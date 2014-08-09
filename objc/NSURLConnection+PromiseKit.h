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

+ (PMKPromise *)GET:(id)urlStringFormatOrURL, ...;
+ (PMKPromise *)GET:(NSString *)string query:(NSDictionary *)parameters;
+ (PMKPromise *)POST:(NSString *)urlString formURLEncodedParameters:(NSDictionary *)parameters;
+ (PMKPromise *)PUT:(NSString *)urlString formURLEncodedParameters:(NSDictionary *)params;
+ (PMKPromise *)DELETE:(NSString *)urlString formURLEncodedParameters:(NSDictionary *)params;
+ (PMKPromise *)promise:(NSURLRequest *)rq;
@end
