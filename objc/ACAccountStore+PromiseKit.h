//
//  Created by merowing on 09/05/2014.
//
//
//

#import <PromiseKit/fwd.h>
#import <Accounts/ACAccountStore.h>


@interface ACAccountStore (PromiseKit)

// thens the result from `[self accountsWithAccountType:type]`
- (PMKPromise *)requestAccessToAccountsWithType:(ACAccountType *)type options:(NSDictionary *)options;
// thens the ACAccountCredentialRenewResult
- (PMKPromise *)renewCredentialsForAccount:(ACAccount *)account;
// thens nothing
- (PMKPromise *)saveAccount:(ACAccount *)account;
// thens nothing
- (PMKPromise *)removeAccount:(ACAccount *)account;

- (PMKPromise *)promiseForAccountsWithType:(ACAccountType *)type options:(NSDictionary *)options PMK_DEPRECATED("Use -requestAccessToAccountsWithType:options:");
- (PMKPromise *)promiseForCredentialsRenewalWithAccount:(ACAccount *)account PMK_DEPRECATED("Use -renewCredentialsForAccount:");
- (PMKPromise *)promiseForAccountSave:(ACAccount *)account PMK_DEPRECATED("Use -saveAccount:");
- (PMKPromise *)promiseForAccountRemoval:(ACAccount *)account PMK_DEPRECATED("Use -removeAccount:");

@end
