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
@class PMKPromise;

extern NSString *const SLRequestPromiseKitErrorDomain;
extern const NSInteger SLRequestPromiseKitServerStatusCodeErrorCode;
extern NSString *const SLRequestPromiseKitOriginalStatusCodeKey;
extern NSString *const SLRequestPromiseKitOriginalResponseDataKey;
extern NSString *const SLRequestPromiseKitResponseDataAsTextKey;

@interface SLRequest (PromiseKit)
+ (PMKPromise *)promise:(SLRequest *)request;
- (PMKPromise *)promise;
@end

@interface ACAccountStore (PromiseKit)
- (PMKPromise *)promiseForAccountsWithType:(ACAccountType *)type options:(NSDictionary *)options;
- (PMKPromise *)promiseForCredentialsRenewalWithAccount:(ACAccount *)account;
- (PMKPromise *)promiseForAccountSave:(ACAccount *)account;
- (PMKPromise *)promiseForAccountRemoval:(ACAccount *)account;
@end

#endif
