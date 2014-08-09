//
//  Created by merowing on 09/05/2014.
//
//
//

#import "PromiseKit/Promise.h"
#import "SLRequest+PromiseKit.h"

NSString *const SLRequestPromiseKitErrorDomain = PMKErrorDomain;
const NSInteger SLRequestPromiseKitServerStatusCodeErrorCode = NSURLErrorBadServerResponse;
NSString *const SLRequestPromiseKitOriginalStatusCodeKey = @"SLRequestPromiseKitOriginalStatusCodeKey";
NSString *const SLRequestPromiseKitOriginalResponseDataKey = PMKURLErrorFailingURLResponseKey;
NSString *const SLRequestPromiseKitResponseDataAsTextKey = PMKURLErrorFailingStringKey;


@implementation SLRequest (PromiseKit)

- (PMKPromise *)promise
{
  return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
    [self performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {

      assert(![NSThread isMainThread]);

      if (error) {
        rejecter(error);
        return;
      }

      NSInteger const statusCode = urlResponse.statusCode;
      if (statusCode < 200 || statusCode >= 300) {

          //TODO also add this code into general rejecter!

        NSMutableDictionary *userInfo = [@{
          @"SLRequestPromiseKitOriginalStatusCodeKey" : @(statusCode),
          PMKURLErrorFailingURLResponseKey : responseData ?: [NSNull null],
          NSLocalizedDescriptionKey : [NSHTTPURLResponse localizedStringForStatusCode:statusCode]
        } mutableCopy];

        if (responseData) {
          NSString *responseDataAsText = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
          if (responseDataAsText) userInfo[PMKURLErrorFailingStringKey] = responseDataAsText;
        }

        rejecter([NSError errorWithDomain:PMKErrorDomain code:NSURLErrorBadServerResponse userInfo:userInfo]);
        return;
      }

      if (PMKHTTPURLResponseIsJSON(urlResponse)) {
        id err = nil;
        id json = [NSJSONSerialization JSONObjectWithData:responseData options:PMKJSONDeserializationOptions error:&err];
        if (err)
          rejecter(err);
        else
          fulfiller(PMKManifold(json, urlResponse, responseData));
      } else {
        fulfiller(PMKManifold(responseData, urlResponse, responseData));
      }
    }];
  }];
}

+ (PMKPromise *)promise:(SLRequest *)request
{
  return [request promise];
}

@end
