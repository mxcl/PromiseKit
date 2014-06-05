#import "Chuzzle.h"
@import CoreFoundation.CFString;
@import CoreFoundation.CFURL;
@import Foundation;
#import "PromiseKit+Foundation.h"
#import "PromiseKit/Promise.h"

NSString const*const PMKURLErrorFailingURLResponse = PMKURLErrorFailingURLResponseKey;
NSString const*const PMKURLErrorFailingData = PMKURLErrorFailingDataKey;



static inline NSString *enc(NSString *in) {
	return (__bridge_transfer  NSString *) CFURLCreateStringByAddingPercentEscapes(
            kCFAllocatorDefault,
            (__bridge CFStringRef)in.description,
            CFSTR("[]."),
            CFSTR(":/?&=;+!@#$()',*"),
            kCFStringEncodingUTF8);
}

static BOOL NSHTTPURLResponseIsJSON(NSHTTPURLResponse *rsp) {
    NSString *type = rsp.allHeaderFields[@"Content-Type"];
    NSArray *bits = [type componentsSeparatedByString:@";"];
    return [bits.chuzzle containsObject:@"application/json"];
}

static BOOL NSHTTPURLResponseIsText(NSHTTPURLResponse *rsp) {
    NSString *type = rsp.allHeaderFields[@"Content-Type"];
    NSArray *bits = [type componentsSeparatedByString:@";"].chuzzle;
    id textTypes = @[@"text/plain", @"text/html", @"text/css"];
    return [bits firstObjectCommonWithArray:textTypes] != nil;
}

#ifdef UIKIT_EXTERN
static BOOL NSHTTPURLResponseIsImage(NSHTTPURLResponse *rsp) {
    NSString *type = rsp.allHeaderFields[@"Content-Type"];
    NSArray *bits = [type componentsSeparatedByString:@";"];
    for (NSString *bit in bits) {
        if ([bit isEqualToString:@"image/jpeg"]) return YES;
        if ([bit isEqualToString:@"image/png"]) return YES;
    };
    return NO;
}
#endif

static NSArray *DoQueryMagic(NSString *key, id value) {
    NSMutableArray *parts = [NSMutableArray new];

    // Sort dictionary keys to ensure consistent ordering in query string,
    // which is important when deserializing potentially ambiguous sequences,
    // such as an array of dictionaries
    #define sortDescriptor [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(compare:)]

    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = value;
        for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[sortDescriptor]]) {
            id recursiveKey = key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey;
            [parts addObjectsFromArray:DoQueryMagic(recursiveKey, dictionary[nestedKey])];
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        for (id nestedValue in value)
            [parts addObjectsFromArray:DoQueryMagic([NSString stringWithFormat:@"%@[]", key], nestedValue)];
    } else if ([value isKindOfClass:[NSSet class]]) {
        for (id obj in [value sortedArrayUsingDescriptors:@[sortDescriptor]])
            [parts addObjectsFromArray:DoQueryMagic(key, obj)];
    } else
        [parts addObjectsFromArray:@[key, value]];

    return parts;

    #undef sortDescriptor
}

NSString *NSDictionaryToURLQueryString(NSDictionary *params) {
    if (!params.chuzzle)
        return nil;
    NSMutableString *s = [NSMutableString new];
    NSEnumerator *e = DoQueryMagic(nil, params).objectEnumerator;
    for (;;) {
        id obj = e.nextObject;
        if (!obj) break;
        [s appendFormat:@"%@=%@&", enc(obj), enc(e.nextObject)];
    }
    [s deleteCharactersInRange:NSMakeRange(s.length-1, 1)];
    return s;
}



@implementation NSURLConnection (PromiseKit)

+ (Promise *)GET:(id)urlFormat, ... {
    if (!urlFormat || urlFormat == [NSNull null])
        return [Promise promiseWithValue:[NSError errorWithDomain:PMKErrorDomain code:PMKErrorCodeInvalidUsage userInfo:nil]];

    if ([urlFormat isKindOfClass:[NSURL class]])
        return [self GET:urlFormat query:nil];
    va_list arguments;
    va_start(arguments, urlFormat);
    urlFormat = [[NSString alloc] initWithFormat:urlFormat arguments:arguments];
    va_end(arguments);
    return [self GET:urlFormat query:nil];
}

+ (Promise *)GET:(id)url query:(NSDictionary *)params {
    if (params.chuzzle) {
        if ([url isKindOfClass:[NSURL class]])
            url = [url absoluteString];
        id query = NSDictionaryToURLQueryString(params);
        url = [NSString stringWithFormat:@"%@?%@", url, query];
    }
    if ([url isKindOfClass:[NSString class]])
        url = [NSURL URLWithString:url];
        
    return [self promise:[NSURLRequest requestWithURL:url]];
}

+ (Promise *)POST:(id)url formURLEncodedParameters:(NSDictionary *)params {
    if ([url isKindOfClass:[NSString class]])
        url = [NSURL URLWithString:url];

    NSMutableURLRequest *rq = [[NSMutableURLRequest alloc] initWithURL:url];
    rq.HTTPMethod = @"POST";

    if (params.chuzzle) {
        [rq addValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        rq.HTTPBody = [NSDictionaryToURLQueryString(params) dataUsingEncoding:NSUTF8StringEncoding];
    }

    return [self promise:rq];
}

NSString *PMKUserAgent() {
    static NSString *ua;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        id info = [NSBundle mainBundle].infoDictionary;
        id name = info[@"CFBundleDisplayName"] ?: info[(__bridge NSString *)kCFBundleIdentifierKey];
        id vers = (__bridge id)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey) ?: info[(__bridge NSString *)kCFBundleVersionKey];
      #ifdef UIKIT_EXTERN
        float scale = ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] ? [UIScreen mainScreen].scale : 1.0f);
        ua = [NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)", name, vers, [UIDevice currentDevice].model, [UIDevice currentDevice].systemVersion, scale];
      #else
        ua = [NSString stringWithFormat:@"%@/%@", name, vers];
      #endif
    });
    return ua;
}

+ (Promise *)promise:(NSURLRequest *)rq {
    static NSOperationQueue *q;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        q = [NSOperationQueue new];
    });

    if (![rq valueForHTTPHeaderField:@"User-Agent"]) {
        if (![rq respondsToSelector:@selector(setValue:forHTTPHeaderField:)])
            rq = rq.mutableCopy;
        [(id)rq setValue:PMKUserAgent() forHTTPHeaderField:@"User-Agent"];
    }

    return [Promise new:^(PromiseFulfiller fluff, PromiseRejecter rejunk){
        [NSURLConnection sendAsynchronousRequest:rq queue:q completionHandler:^(id rsp, id data, NSError *urlError) {

            assert(![NSThread isMainThread]);

            PromiseFulfiller fulfiller = ^(id responseObject){
                fluff(PMKManifold(responseObject, rsp, data));
            };
            PromiseRejecter rejecter = ^(NSError *error){
                id userInfo = error.userInfo.mutableCopy ?: [NSMutableDictionary new];
                if (data) userInfo[PMKURLErrorFailingDataKey] = data;
                if (rsp) userInfo[PMKURLErrorFailingURLResponseKey] = rsp;
                error = [NSError errorWithDomain:error.domain code:error.code userInfo:userInfo];
                rejunk(error);
            };

            if (urlError) {
                rejecter(urlError);
            } else if ([rsp statusCode] < 200 || [rsp statusCode] >= 300) {
                id info = @{
                    NSLocalizedDescriptionKey: @"The server returned a bad HTTP response code",
                    NSURLErrorFailingURLStringErrorKey: rq.URL.absoluteString,
                    NSURLErrorFailingURLErrorKey: rq.URL
                };
                id err = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:info];
                rejecter(err);
            } else if (NSHTTPURLResponseIsJSON(rsp)) {
                id err = nil;
                id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&err];
                if (err)
                    rejecter(err);
                else
                    fulfiller(json);
          #ifdef UIKIT_EXTERN
            } else if (NSHTTPURLResponseIsImage(rsp)) {
                UIImage *image = [[UIImage alloc] initWithData:data];
                image = [[UIImage alloc] initWithCGImage:[image CGImage] scale:image.scale orientation:image.imageOrientation];
                if (image)
                    fulfiller(image);
                else {
                    id info = @{
                        NSLocalizedDescriptionKey: @"The server returned invalid image data",
                        NSURLErrorFailingURLStringErrorKey: rq.URL.absoluteString,
                        NSURLErrorFailingURLErrorKey: rq.URL
                    };
                    id err = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:info];
                    rejecter(err);
                }
          #endif
            } else if (NSHTTPURLResponseIsText(rsp)) {
                id str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                if (str)
                    fulfiller(str);
                else {
                    id info = @{
                        NSLocalizedDescriptionKey: @"The server returned invalid string data",
                        NSURLErrorFailingURLStringErrorKey: rq.URL.absoluteString,
                        NSURLErrorFailingURLErrorKey: rq.URL
                    };
                    id err = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:info];
                    rejecter(err);
                }
            } else
                fulfiller(data);
        }];
    }];

    #undef fulfiller
}

@end
