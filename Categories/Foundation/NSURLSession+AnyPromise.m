#import "NSURLSession+AnyPromise.h"
#import <PromiseKit/PromiseKit.h>
// When using Carthage add `github "mxcl/OMGHTTPURLRQ"` to your Cartfile.
#import <OMGHTTPURLRQ/OMGHTTPURLRQ.h>
#import <OMGHTTPURLRQ/OMGUserAgent.h>


typedef void (^PMKURLDataCompletionHandler)(NSData *, NSURLResponse *, NSError *);
PMKURLDataCompletionHandler PMKMakeURLDataHandler(NSURLRequest *, PMKResolver);
extern id PMKURLRequestFromURLFormat(NSError **err, id urlFormat, ...);


@implementation NSURLSession (PromiseKit)

+ (AnyPromise *)GET:(id)urlFormat, ... {
    id err;
    id rq = PMKURLRequestFromURLFormat(&err, urlFormat);
    if (err) {
        return [AnyPromise promiseWithValue:err];
    } else {
        return [self promise:rq];
    }
}

+ (AnyPromise *)GET:(NSString *)url query:(NSDictionary *)params {
    id err;
    id rq = [OMGHTTPURLRQ GET:url:params error:&err];
    if (err) return [AnyPromise promiseWithValue:err];
    return [self promise:rq];
}

+ (AnyPromise *)POST:(NSString *)url formURLEncodedParameters:(NSDictionary *)params {
    id err;
    id rq = [OMGHTTPURLRQ POST:url:params error:&err];
    if (err) return [AnyPromise promiseWithValue:err];
    return [self promise:rq];
}

+ (AnyPromise *)POST:(NSString *)urlString JSON:(NSDictionary *)params {
    id err;
    id rq = [OMGHTTPURLRQ POST:urlString JSON:params error:&err];
    if (err) [AnyPromise promiseWithValue:err];
    return [self promise:rq];
}

+ (AnyPromise *)PUT:(NSString *)url formURLEncodedParameters:(NSDictionary *)params {
    id err;
    id rq = [OMGHTTPURLRQ PUT:url:params error:&err];
    if (err) [AnyPromise promiseWithValue:err];
    return [self promise:rq];

}

+ (AnyPromise *)DELETE:(NSString *)url formURLEncodedParameters:(NSDictionary *)params {
    id err;
    id rq = [OMGHTTPURLRQ DELETE:url :params error:&err];
    if (err) [AnyPromise promiseWithValue:err];
    return [self promise:rq];
}

+ (AnyPromise *)PATCH:(NSString *)url JSON:(NSDictionary *)params {
    id err;
    id rq = [OMGHTTPURLRQ PATCH:url JSON:params error:&err];
    if (err) [AnyPromise promiseWithValue:err];
    return [self promise:rq];
}

+ (AnyPromise *)promise:(NSURLRequest *)rq {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [[NSURLSession sharedSession] dataTaskWithRequest:rq completionHandler:PMKMakeURLDataHandler(rq, resolve)];
    }];
}

@end
