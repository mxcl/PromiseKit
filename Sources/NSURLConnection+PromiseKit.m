#import <CoreFoundation/CFString.h>
#import <CoreFoundation/CFURL.h>
#import <Foundation/NSJSONSerialization.h>
#import <Foundation/NSThread.h>
#import <Foundation/NSURLError.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSURLResponse.h>
#import "NSURLConnection+PromiseKit.h"
#import <OMGHTTPURLRQ/OMGHTTPURLRQ.h>
#import <PromiseKit/Promise.h>

NSString const*const PMKURLErrorFailingURLResponse = PMKURLErrorFailingURLResponseKey;
NSString const*const PMKURLErrorFailingData = PMKURLErrorFailingDataKey;


@implementation NSURLConnection (PromiseKit)

+ (PMKPromise *)GET:(id)urlFormat, ... {
    if ([urlFormat isKindOfClass:[NSString class]]) {
        va_list arguments;
        va_start(arguments, urlFormat);
        urlFormat = [[NSString alloc] initWithFormat:urlFormat arguments:arguments];
        va_end(arguments);
    } else if ([urlFormat isKindOfClass:[NSURL class]]) {
        NSMutableURLRequest *rq = [[NSMutableURLRequest alloc] initWithURL:urlFormat];
        [rq setValue:OMGUserAgent() forHTTPHeaderField:@"User-Agent"];
        return [self promise:rq];
    } else {
        urlFormat = [urlFormat description];
    }
    id err;
    id rq = [OMGHTTPURLRQ GET:urlFormat:nil error:&err];
    if (err) {
        return [PMKPromise promiseWithValue:err];
    } else {
        return [self promise:rq];
    }
}

+ (PMKPromise *)GET:(NSString *)url query:(NSDictionary *)params {
    id err;
    id rq = [OMGHTTPURLRQ GET:url:params error:&err];
    if (err) return [PMKPromise promiseWithValue:err];
    return [self promise:rq];
}

+ (PMKPromise *)POST:(NSString *)url formURLEncodedParameters:(NSDictionary *)params {
    id err;
    id rq = [OMGHTTPURLRQ POST:url:params error:&err];
    if (err) return [PMKPromise promiseWithValue:err];
    return [self promise:rq];
}

+ (PMKPromise *)POST:(NSString *)urlString JSON:(NSDictionary *)params {
    id err;
    id rq = [OMGHTTPURLRQ POST:urlString JSON:params error:&err];
    if (err) [PMKPromise promiseWithValue:err];
    return [self promise:rq];
}

+ (PMKPromise *)PUT:(NSString *)url formURLEncodedParameters:(NSDictionary *)params {
    id err;
    id rq = [OMGHTTPURLRQ PUT:url:params error:&err];
    if (err) [PMKPromise promiseWithValue:err];
    return [self promise:rq];

}

+ (PMKPromise *)DELETE:(NSString *)url formURLEncodedParameters:(NSDictionary *)params {
    id err;
    id rq = [OMGHTTPURLRQ DELETE:url :params error:&err];
    if (err) [PMKPromise promiseWithValue:err];
    return [self promise:rq];
}

+ (PMKPromise *)PATCH:(NSString *)url JSON:(NSDictionary *)params {
    id err;
    id rq = [OMGHTTPURLRQ PATCH:url JSON:params error:&err];
    if (err) [PMKPromise promiseWithValue:err];
    return [self promise:rq];
}

+ (PMKPromise *)promise:(NSURLRequest *)rq {
    return [PMKPromise new:^(PMKPromiseFulfiller fluff, PMKPromiseRejecter rejunk){
        [NSURLConnection sendAsynchronousRequest:rq queue:PMKOperationQueue() completionHandler:^(id rsp, id data, NSError *urlError) {

            assert(![NSThread isMainThread]);

            PMKPromiseFulfiller fulfiller = ^(id responseObject){
                fluff(PMKManifold(responseObject, rsp, data));
            };
            PMKPromiseRejecter rejecter = ^(NSError *error){
                NSMutableDictionary *userInfo = error.userInfo.mutableCopy ?: [NSMutableDictionary new];
                if (data) userInfo[PMKURLErrorFailingDataKey] = data;
                if (rsp) userInfo[PMKURLErrorFailingURLResponseKey] = rsp;
                error = [NSError errorWithDomain:error.domain code:error.code userInfo:userInfo];
                rejunk(error);
            };

            NSStringEncoding (^stringEncoding)(void) = ^NSStringEncoding{
                id encodingName = [rsp textEncodingName];
                if (encodingName) {
                    CFStringEncoding encoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)encodingName);
                    if (encoding != kCFStringEncodingInvalidId)
                        return CFStringConvertEncodingToNSStringEncoding(encoding);
                }
                return NSUTF8StringEncoding;
            };

            if (urlError) {
                rejecter(urlError);
            } else if (![rsp isKindOfClass:[NSHTTPURLResponse class]]) {
                fulfiller(data);
            } else if ([rsp statusCode] < 200 || [rsp statusCode] >= 300) {
                id info = @{
                    NSLocalizedDescriptionKey: @"The server returned a bad HTTP response code",
                    NSURLErrorFailingURLStringErrorKey: rq.URL.absoluteString,
                    NSURLErrorFailingURLErrorKey: rq.URL
                };
                id err = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:info];
                rejecter(err);
            } else if (PMKHTTPURLResponseIsJSON(rsp)) {
                // work around ever-so-common Rails workaround: https://github.com/rails/rails/issues/1742
                if ([rsp expectedContentLength] == 1 && [data isEqualToData:[NSData dataWithBytes:" " length:1]])
                    return fulfiller(nil);

                NSError *err = nil;
                id json = [NSJSONSerialization JSONObjectWithData:data options:PMKJSONDeserializationOptions error:&err];
                if (!err) {
                    fulfiller(json);
                } else {
                    id userInfo = err.userInfo.mutableCopy;
                    if (data) {
                        NSString *string = [[NSString alloc] initWithData:data encoding:stringEncoding()];
                        if (string)
                            userInfo[PMKURLErrorFailingStringKey] = string;
                    }
                    long long length = [rsp expectedContentLength];
                    id bytes = length <= 0 ? @"" : [NSString stringWithFormat:@"%lld bytes", length];
                    id fmt = @"The server claimed a%@ JSON response, but decoding failed with: %@";
                    userInfo[NSLocalizedDescriptionKey] = [NSString stringWithFormat:fmt, bytes, userInfo[NSLocalizedDescriptionKey]];
                    err = [NSError errorWithDomain:err.domain code:err.code userInfo:userInfo];
                    rejecter(err);
                }
          #ifdef UIKIT_EXTERN
            } else if (PMKHTTPURLResponseIsImage(rsp)) {
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
                    id err = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotDecodeContentData userInfo:info];
                    rejecter(err);
                }
          #endif
            } else if (PMKHTTPURLResponseIsText(rsp)) {
                id str = [[NSString alloc] initWithData:data encoding:stringEncoding()];
                if (str)
                    fulfiller(str);
                else {
                    id info = @{
                        NSLocalizedDescriptionKey: @"The server returned invalid string data",
                        NSURLErrorFailingURLStringErrorKey: rq.URL.absoluteString,
                        NSURLErrorFailingURLErrorKey: rq.URL
                    };
                    id err = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotDecodeContentData userInfo:info];
                    rejecter(err);
                }
            } else
                fulfiller(data);
        }];
    }];

    #undef fulfiller
}

@end
