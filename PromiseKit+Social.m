//
//  Created by merowing on 09/05/2014.
//
//
//

#import "Private/PromiseKit.ph"
#import "PromiseKit+Social.h"
#import "PromiseKit/Promise.h"

#if PMK_iOS6_ISH

NSString *const SLRequestPromiseKitErrorDomain = @"SLRequestPromiseKitErrorDomain";
const NSInteger SLRequestPromiseKitServerStatusCodeErrorCode = 1;
NSString *const SLRequestPromiseKitOriginalStatusCodeKey = @"SLRequestPromiseKitOriginalStatusCodeKey";
NSString *const SLRequestPromiseKitOriginalResponseDataKey = @"SLRequestPromiseKitOriginalResponseDataKey";
NSString *const SLRequestPromiseKitResponseDataAsTextKey = @"SLRequestPromiseKitResponseDataAsTextKey";

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
        NSString *localizedStatusCode = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];

        NSMutableDictionary *userInfo = [@{
          SLRequestPromiseKitOriginalStatusCodeKey : @(statusCode),
          SLRequestPromiseKitOriginalResponseDataKey : responseData ?: [NSNull null],
          NSLocalizedDescriptionKey : localizedStatusCode
        } mutableCopy];

        if (responseData) {
          NSString *responseDataAsText = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
          userInfo[SLRequestPromiseKitResponseDataAsTextKey] = responseDataAsText ?: [NSNull null];
        }

        rejecter([NSError errorWithDomain:SLRequestPromiseKitErrorDomain code:SLRequestPromiseKitServerStatusCodeErrorCode userInfo:userInfo]);
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

#endif
