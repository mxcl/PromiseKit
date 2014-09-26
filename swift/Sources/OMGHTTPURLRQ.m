#import <CoreFoundation/CFURL.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSJSONSerialization.h>
#import <Foundation/NSURL.h>
#import "PromiseKit.h"
#import <stdlib.h>


static inline NSString *enc(NSString *in) {
	return (__bridge_transfer  NSString *) CFURLCreateStringByAddingPercentEscapes(
            kCFAllocatorDefault,
            (__bridge CFStringRef)in.description,
            CFSTR("[]."),
            CFSTR(":/?&=;+!@#$()',*"),
            kCFStringEncodingUTF8);
}

static inline NSMutableURLRequest *OMGMutableURLRequest() {
    NSMutableURLRequest *rq = [NSMutableURLRequest new];
    [rq setValue:OMGUserAgent() forHTTPHeaderField:@"User-Agent"];
    return rq;
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
    } else {
        [parts addObjectsFromArray:[NSArray arrayWithObjects:key, value, nil]];
    }

    return parts;

    #undef sortDescriptor
}

NSString *NSDictionaryToURLQueryString(NSDictionary *params) {
    if (params.count == 0)
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



@implementation OMGMultipartFormData {
@public
    NSString *boundary;
    NSMutableData *body;
}

- (instancetype)init {
    body = [NSMutableData data];
    boundary = [NSString stringWithFormat:@"------------------------%08X%08X", arc4random(), arc4random()];
    return self;
}

- (void)add:(NSData *)payload :(NSString *)name :(NSString *)filename :(NSString *)contentType {
    id ln1 = [NSString stringWithFormat:@"--%@\r\n", boundary];
    id ln2 = ({
        id s = [NSMutableString stringWithString:@"Content-Disposition: form-data; "];
        [s appendFormat:@"name=\"%@\"", name];
        if (filename.length)
            [s appendFormat:@"; filename=\"%@\"", filename];
        [s appendString:@"\r\n"];
        if (contentType.length)
            [s appendFormat:@"Content-Type: %@\r\n", contentType];
        [s appendString:@"\r\n"];
        s;
    });

    [body appendData:[ln1 dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[ln2 dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:payload];
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)addFile:(NSData *)payload parameterName:(NSString *)name filename:(NSString *)filename contentType:(NSString *)contentType
{
    [self add:payload:name:filename:(contentType ?: @"application/octet-stream")];
}

- (void)addText:(NSString *)text parameterName:(NSString *)parameterName {
    [self add:[text dataUsingEncoding:NSUTF8StringEncoding]:parameterName:nil:nil];
}

- (void)addParameters:(NSDictionary *)parameters {
    for (id key in parameters)
        [self addText:[parameters[key] description] parameterName:key];
}

@end



@implementation OMGHTTPURLRQ

+ (NSMutableURLRequest *)GET:(NSString *)url :(NSDictionary *)params {
    id queryString = NSDictionaryToURLQueryString(params);
    if (queryString) url = [url stringByAppendingFormat:@"?%@", queryString];
    NSMutableURLRequest *rq = OMGMutableURLRequest();
    rq.HTTPMethod = @"GET";
    rq.URL = [NSURL URLWithString:url];
    return rq;
}

static NSMutableURLRequest *OMGFormURLEncodedRequest(NSString *url, NSString *method, NSDictionary *parameters) {
    NSMutableURLRequest *rq = OMGMutableURLRequest();
    rq.URL = [NSURL URLWithString:url];
    rq.HTTPMethod = method;
    
    id queryString = NSDictionaryToURLQueryString(parameters);
    NSData *data = [queryString dataUsingEncoding:NSUTF8StringEncoding];
    [rq addValue:@"8bit" forHTTPHeaderField:@"Content-Transfer-Encoding"];
    [rq addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [rq addValue:@(data.length).description forHTTPHeaderField:@"Content-Length"];
    [rq setHTTPBody:data];
    
    return rq;
}

+ (NSMutableURLRequest *)POST:(NSString *)url :(id)body {
    if (![body isKindOfClass:[OMGMultipartFormData class]]) {
        return OMGFormURLEncodedRequest(url, @"POST", body);
    } else {
        OMGMultipartFormData *multipartFormData = (id)body;
        id const charset = (NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
        id const contentType = [NSString stringWithFormat:@"multipart/form-data; charset=%@; boundary=%@", charset, multipartFormData->boundary];

        NSMutableData *data = [multipartFormData->body mutableCopy];
        id lastLine = [NSString stringWithFormat:@"\r\n--%@--\r\n", multipartFormData->boundary];
        [data appendData:[lastLine dataUsingEncoding:NSUTF8StringEncoding]];

        NSMutableURLRequest *rq = OMGMutableURLRequest();
        [rq setURL:[NSURL URLWithString:url]];
        [rq setHTTPMethod:@"POST"];
        [rq addValue:contentType forHTTPHeaderField:@"Content-Type"];
        [rq setHTTPBody:data];
        return rq;
    }
}

+ (NSMutableURLRequest *)POST:(NSString *)url JSON:(id)params {
    NSMutableURLRequest *rq = OMGMutableURLRequest();
    rq.URL = [NSURL URLWithString:url];
    rq.HTTPMethod = @"POST";
    rq.HTTPBody = [NSJSONSerialization dataWithJSONObject:params options:(NSJSONWritingOptions)0 error:nil];
    [rq setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [rq setValue:@"json" forHTTPHeaderField:@"Data-Type"];
    return rq;
}

+ (NSMutableURLRequest *)PUT:(NSString *)url :(NSDictionary *)parameters {
    return OMGFormURLEncodedRequest(url, @"PUT", parameters);
}

+ (NSMutableURLRequest *)PUT:(NSString *)url JSON:(id)params {
    NSMutableURLRequest *rq = [OMGHTTPURLRQ POST:url JSON:params];
    rq.HTTPMethod = @"PUT";
    return rq;
}

+ (NSMutableURLRequest *)DELETE:(NSString *)url :(NSDictionary *)parameters {
    return OMGFormURLEncodedRequest(url, @"DELETE", parameters);
}

@end
