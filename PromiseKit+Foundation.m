#import "Chuzzle.h"
@import CoreFoundation.CFString;
@import CoreFoundation.CFURL;
@import Foundation.NSJSONSerialization;
@import Foundation.NSOperation;
@import Foundation.NSSortDescriptor;
@import Foundation.NSURL;
@import Foundation.NSURLError;
@import Foundation.NSURLResponse;
#import "PromiseKit/Deferred.h"
#import "PromiseKit+Foundation.h"
#import "PromiseKit/Promise.h"

#define PMKURLErrorWithCode(x) [NSError errorWithDomain:NSURLErrorDomain code:x userInfo:NSDictionaryExtend(@{PMKURLErrorFailingURLResponse: rsp}, error.userInfo)]



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

static NSDictionary *NSDictionaryExtend(NSDictionary *add, NSDictionary *base) {
    base = base.mutableCopy;
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

static void ProcessURLResponse(NSHTTPURLResponse *rsp, NSData *data, Deferred *deferred) {
    if (NSHTTPURLResponseIsJSON(rsp)) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            id error = nil;
            id json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error)
                    [deferred reject:error];
                else
                    [deferred resolve:json];
            });
        });
#ifdef UIKIT_EXTERN
    } else if (NSHTTPURLResponseIsImage(rsp)) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *image = [[UIImage alloc] initWithData:data];
            image = [[UIImage alloc] initWithCGImage:[image CGImage] scale:image.scale orientation:image.imageOrientation];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (image)
                    [deferred resolve:image];
                else
                    [deferred reject:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:nil]];
            });
        });
#endif
    } else
        [deferred resolve:data];
}


@implementation NSURLConnection (PromiseKit)

+ (Promise *)GET:(id)urlFormat, ... {
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

    if (params.chuzzle) {
        [rq addValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        rq.HTTPBody = [NSDictionaryToURLQueryString(params) dataUsingEncoding:NSUTF8StringEncoding];
    }

    return [self promise:rq];
}

+ (Promise *)promise:(NSURLRequest *)rq {
    Deferred *deferred = [Deferred new];
    id q = [NSOperationQueue currentQueue] ?: [NSOperationQueue mainQueue];

    [NSURLConnection sendAsynchronousRequest:rq queue:q completionHandler:^(id rsp, id data, NSError *error) {
        if (error) {
            NSLog(@"PromiseKit: %@", error);
            [deferred reject:rsp ? PMKURLErrorWithCode(error.code) : error];
        } else if ([rsp statusCode] != 200) {
            NSLog(@"PromiseKit: bad response code: %ld", (long)[rsp statusCode]);
            [deferred reject:PMKURLErrorWithCode(NSURLErrorBadServerResponse)];
        } else
            ProcessURLResponse(rsp, data, deferred);
    }];
    return deferred.promise;
}

@end



@implementation NSURLCache (PromiseKit)

- (Promise *)promisedResponseForRequest:(NSURLRequest *)rq {
    Deferred *deferred = [Deferred new];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSCachedURLResponse *rsp = [self cachedResponseForRequest:rq];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!rsp || [(id)rsp.response statusCode] != 200) {
                [deferred resolve:nil];
            } else
                ProcessURLResponse((id)rsp.response, rsp.data, deferred);
        });
    });
    return deferred.promise;
}

@end
