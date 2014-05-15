#import "Chuzzle.h"
@import CoreFoundation.CFString;
@import CoreFoundation.CFURL;
@import Foundation.NSBundle;
@import Foundation.NSError;
@import Foundation.NSJSONSerialization;
@import Foundation.NSOperation;
@import Foundation.NSSortDescriptor;
@import Foundation.NSURL;
@import Foundation.NSURLError;
@import Foundation.NSURLResponse;
#import "PromiseKit+Foundation.h"
#import "PromiseKit/Promise.h"


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

static inline NSDictionary *NSDictionaryExtend(NSDictionary *add, NSDictionary *base) {
    base = base.mutableCopy ?: [NSMutableDictionary new];
    [(id)base addEntriesFromDictionary:add];
    return base;
}

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
    id q = [NSOperationQueue currentQueue] ?: [NSOperationQueue mainQueue];

    if (![rq valueForHTTPHeaderField:@"User-Agent"]) {
        if (![rq respondsToSelector:@selector(setValue:forHTTPHeaderField:)])
            rq = rq.mutableCopy;
        [(id)rq setValue:PMKUserAgent() forHTTPHeaderField:@"User-Agent"];
    }

    #define NSURLError(x, desc) [NSError errorWithDomain:NSURLErrorDomain code:x userInfo:NSDictionaryExtend(@{PMKURLErrorFailingURLResponse: rsp, NSLocalizedDescriptionKey: desc}, error.userInfo)]
    #define fulfiller(obj) fulfiller(PMKManifold(obj, rsp, data))

    return [Promise new:^(PromiseResolver fulfiller, PromiseResolver rejecter){
        [NSURLConnection sendAsynchronousRequest:rq queue:q completionHandler:^(id rsp, id data, NSError *error) {
            if (error) {
                if (rsp) {
                    id dict = NSDictionaryExtend(@{PMKURLErrorFailingURLResponse: rsp}, error.userInfo);
                    error = [NSError errorWithDomain:error.domain code:error.code userInfo:dict];
                }
                rejecter(error);
            } else if ([rsp statusCode] < 200 || [rsp statusCode] >= 300) {
                id err = NSURLError(NSURLErrorBadServerResponse, @"bad HTTP response code");
                rejecter(err);
            } else if (NSHTTPURLResponseIsJSON(rsp)) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    id err = nil;
                    id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&err];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (err)
                            rejecter(err);
                        else
                            fulfiller(json);
                    });
                });
          #ifdef UIKIT_EXTERN
            } else if (NSHTTPURLResponseIsImage(rsp)) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    UIImage *image = [[UIImage alloc] initWithData:data];
                    image = [[UIImage alloc] initWithCGImage:[image CGImage] scale:image.scale orientation:image.imageOrientation];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (image)
                            fulfiller(image);
                        else {
                            id err = NSURLError(NSURLErrorBadServerResponse, @"invalid image data");
                            rejecter(err);
                        }
                    });
                });
          #endif
            } else
                fulfiller(data);
        }];
    }];

    #undef fulfiller
}

@end
