#import <Chuzzle.h>
@import CoreFoundation.CFString;
@import CoreFoundation.CFURL;
@import Foundation;
#import "Foundation+PromiseKit.h"
#import <OMGHTTPURLRQ.h>
#import "Private/PromiseKit.ph"
#import "PromiseKit/Promise.h"

NSString const*const PMKURLErrorFailingURLResponse = PMKURLErrorFailingURLResponseKey;
NSString const*const PMKURLErrorFailingData = PMKURLErrorFailingDataKey;

static BOOL NSHTTPURLResponseIsText(NSHTTPURLResponse *rsp) {
    NSString *type = rsp.allHeaderFields[@"Content-Type"];
    NSArray *bits = [type componentsSeparatedByString:@";"].chuzzle;
    id textTypes = @[@"text/plain", @"text/html", @"text/css"];
    return [bits firstObjectCommonWithArray:textTypes] != nil;
}

#ifdef UIKIT_EXTERN
static BOOL NSHTTPURLResponseIsImage(NSHTTPURLResponse *rsp) {
    NSString *type = rsp.allHeaderFields[@"Content-Type"];
    NSArray *bits = [type componentsSeparatedByString:@";"].chuzzle;
    for (NSString *bit in bits) {
        if ([bit isEqualToString:@"image/jpeg"]) return YES;
        if ([bit isEqualToString:@"image/png"]) return YES;
    };
    return NO;
}
#endif


@implementation NSURLConnection (PromiseKit)

+ (PMKPromise *)GET:(id)urlFormat, ... {
    if (!urlFormat || urlFormat == [NSNull null])
        return [PMKPromise promiseWithValue:[NSError errorWithDomain:PMKErrorDomain code:PMKInvalidUsageError userInfo:nil]];

    va_list arguments;
    va_start(arguments, urlFormat);
    urlFormat = [[NSString alloc] initWithFormat:urlFormat arguments:arguments];
    va_end(arguments);

    return [self promise:[OMGHTTPURLRQ GET:urlFormat:nil]];
}

+ (PMKPromise *)GET:(id)url query:(NSDictionary *)params {
    return [self promise:[OMGHTTPURLRQ GET:url:params]];
}

+ (PMKPromise *)POST:(id)url formURLEncodedParameters:(NSDictionary *)params {
    return [self promise:[OMGHTTPURLRQ POST:url:params]];
}

+ (PMKPromise *)PUT:(id)url formURLEncodedParameters:(NSDictionary *)params {
    return [self promise:[OMGHTTPURLRQ PUT:url:params]];
}

+ (PMKPromise *)DELETE:(id)url formURLEncodedParameters:(NSDictionary *)params {
    return [self promise:[OMGHTTPURLRQ DELETE:url:params]];
}


+ (PMKPromise *)promise:(NSURLRequest *)rq {
    static NSOperationQueue *q;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        q = [NSOperationQueue new];
    });

    return [PMKPromise new:^(PMKPromiseFulfiller fluff, PMKPromiseRejecter rejunk){
        [NSURLConnection sendAsynchronousRequest:rq queue:q completionHandler:^(id rsp, id data, NSError *urlError) {

            assert(![NSThread isMainThread]);

            PMKPromiseFulfiller fulfiller = ^(id responseObject){
                fluff(PMKManifold(responseObject, rsp, data));
            };
            PMKPromiseRejecter rejecter = ^(NSError *error){
                id userInfo = error.userInfo.mutableCopy ?: [NSMutableDictionary new];
                if (data) userInfo[PMKURLErrorFailingDataKey] = data;
                if (rsp) userInfo[PMKURLErrorFailingURLResponseKey] = rsp;
                error = [NSError errorWithDomain:error.domain code:error.code userInfo:userInfo];
                rejunk(error);
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
                id err = nil;
                id json = [NSJSONSerialization JSONObjectWithData:data options:PMKJSONDeserializationOptions error:&err];
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
