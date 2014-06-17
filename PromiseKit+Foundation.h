@import Foundation.NSDictionary;
@import Foundation.NSURLCache;
@import Foundation.NSURLConnection;
@import Foundation.NSURLRequest;
@class PMKPromise;

#define PMKURLErrorFailingURLResponseKey @"PMKURLErrorFailingURLResponseKey"
#define PMKURLErrorFailingDataKey @"PMKURLErrorFailingDataKey"

extern NSString const*const PMKURLErrorFailingURLResponse __attribute__((deprecated("Use PMKURLErrorFailingURLResponseKey")));
extern NSString const*const PMKURLErrorFailingData __attribute__((deprecated("Use PMKURLErrorFailingDataKey")));



@interface NSURLConnection (PromiseKit)
+ (PMKPromise *)GET:(id)stringFormatOrNSURL, ...;
+ (PMKPromise *)GET:(id)stringOrURL query:(NSDictionary *)parameters;
+ (PMKPromise *)POST:(id)stringOrURL formURLEncodedParameters:(NSDictionary *)parameters;
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
