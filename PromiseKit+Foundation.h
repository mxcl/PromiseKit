@import Foundation.NSDictionary;
@import Foundation.NSURLCache;
@import Foundation.NSURLConnection;
@import Foundation.NSURLRequest;
@class Promise;

#define PMKURLErrorFailingURLResponseKey @"PMKURLErrorFailingURLResponseKey"
#define PMKURLErrorFailingDataKey @"PMKURLErrorFailingDataKey"

extern NSString const*const PMKURLErrorFailingURLResponse __attribute__((deprecated("Use PMKURLErrorFailingURLResponseKey")));
extern NSString const*const PMKURLErrorFailingData __attribute__((deprecated("Use PMKURLErrorFailingDataKey")));



@interface NSURLConnection (PromiseKit)
+ (Promise *)GET:(id)stringFormatOrNSURL, ...;
+ (Promise *)GET:(id)stringOrURL query:(NSDictionary *)parameters;
+ (Promise *)POST:(id)stringOrURL formURLEncodedParameters:(NSDictionary *)parameters;
+ (Promise *)promise:(NSURLRequest *)rq;
@end



// ideally this would be from a pod, but I looked and all the pods imposed
// too much symbol overhead or used catgeories
NSString *NSDictionaryToURLQueryString(NSDictionary *parameters);


/**
 A sensible User-Agent string, that by default we set on your requests if you
 didn’t set your own.
*/
NSString *PMKUserAgent();
