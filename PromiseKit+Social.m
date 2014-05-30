//
//  Created by merowing on 09/05/2014.
//
//
//


#import "PromiseKit+Social.h"
#import "PromiseKit/Promise.h"

#ifdef PMK_DEPLOY_6

NSString *const SLRequestPromiseKitErrorDomain = @"SLRequestPromiseKitErrorDomain";
const NSInteger SLRequestPromiseKitServerStatusCodeErrorCode = 1;
NSString *const SLRequestPromiseKitOriginalStatusCodeKey = @"SLRequestPromiseKitOriginalStatusCodeKey";
NSString *const SLRequestPromiseKitOriginalResponseDataKey = @"SLRequestPromiseKitOriginalResponseDataKey";
NSString *const SLRequestPromiseKitResponseDataAsTextKey = @"SLRequestPromiseKitResponseDataAsTextKey";

@implementation SLRequest (PromiseKit)
+ (Promise *)promise:(SLRequest *)request
{
  return [Promise new:^(PromiseFulfiller fulfiller, PromiseRejecter rejecter) {
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        if (!responseData) {
          rejecter(error);
          return;
        }

        NSInteger statusCode = urlResponse.statusCode;
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

        fulfiller(PMKManifold(responseData, urlResponse));
      });
    }];
  }

  ];
}

- (Promise *)promise
{
  return [SLRequest promise:self];
}

@end

@implementation ACAccountStore (PromiseKit)
- (Promise *)promiseForAccountsWithType:(ACAccountType *)type options:(NSDictionary *)options
{
  return [Promise new:^(PromiseFulfiller fulfiller, PromiseRejecter rejecter) {
    [self requestAccessToAccountsWithType:type options:options completion:^(BOOL granted, NSError *error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        if (!granted) {
          rejecter(error);
          return;
        }

        fulfiller([self accountsWithAccountType:type]);
      });
    }];
  }];
}

- (Promise *)promiseForCredentialsRenewalWithAccount:(ACAccount *)account
{
  return [Promise new:^(PromiseFulfiller fulfiller, PromiseRejecter rejecter) {
    [self renewCredentialsForAccount:account completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
          rejecter(error);
          return;
        }

        fulfiller(@(renewResult));
      });
    }];
  }];
}

- (Promise *)promiseForAccountSave:(ACAccount *)account
{
  return [Promise new:^(PromiseFulfiller fulfiller, PromiseRejecter rejecter) {
    [self saveAccount:account withCompletionHandler:^(BOOL success, NSError *error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        if (!success) {
          rejecter(error);
          return;
        }

        fulfiller(nil);
      });
    }];
  }];
}

- (Promise *)promiseForAccountRemoval:(ACAccount *)account
{
  return [Promise new:^(PromiseFulfiller fulfiller, PromiseRejecter rejecter) {
    [self removeAccount:account withCompletionHandler:^(BOOL success, NSError *error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        if (!success) {
          rejecter(error);
          return;
        }

        fulfiller(nil);
      });
    }];
  }];
}

@end

#endif