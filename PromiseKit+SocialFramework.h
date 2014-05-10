//
//  Created by merowing on 09/05/2014.
//
//
//

#define PMK_DEPLOY_6 ((defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1080) \
                   || (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000))

#if PMK_DEPLOY_6

@import Social.SLRequest;
@import Accounts;
@class Promise;

extern NSString *const SLRequestPromiseKitErrorDomain;
extern const NSInteger SLRequestPromiseKitServerStatusCodeErrorCode;
extern NSString *const SLRequestPromiseKitOriginalStatusCodeKey;
extern NSString *const SLRequestPromiseKitOriginalResponseDataKey;
extern NSString *const SLRequestPromiseKitResponseDataAsTextKey;

@interface SLRequest (PromiseKit)
+ (Promise *)promise:(SLRequest *)request;
- (Promise *)promise;
@end

@interface ACAccountStore (PromiseKit)
- (Promise *)promiseForAccountsWithType:(ACAccountType *)type options:(NSDictionary *)options;
- (Promise *)promiseForCredentialsRenewalWithAccount:(ACAccount *)account;
- (Promise *)promiseForAccountSave:(ACAccount *)account;
- (Promise *)promiseForAccountRemoval:(ACAccount *)account;
@end

#endif
