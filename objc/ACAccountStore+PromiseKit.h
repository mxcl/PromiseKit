//
//  Created by merowing on 09/05/2014.
//
//
//

#import <PromiseKit/fwd.h>
#import <Accounts/ACAccountStore.h>

/**
 To import the `ACAccountStore` category:

    pod "PromiseKit/ACAccountStore"

 Or you can import all categories on `Accounts`:

    pod "PromiseKit/Accounts"
*/
@interface ACAccountStore (PromiseKit)

/**
 Obtains permission to access protected user properties.

 @param accountType	The account type.
 @param options Can be nil.

 @return A promise that resolves when the requested permissions have been
 successfully obtained. The promise thens all accounts of the specified
 type.

 @see requestAccessToAccountsWithType:options:completion:
*/
- (PMKPromise *)requestAccessToAccountsWithType:(ACAccountType *)type options:(NSDictionary *)options;

/**
 Renews account credentials when the credentials are no longer valid.

 @param account The account to renew credentials.

 @return A promise that thens the `ACAccountCredentialRenewResult`.
*/
- (PMKPromise *)renewCredentialsForAccount:(ACAccount *)account;

/**
 Saves an account to the Accounts database.

 @param account The account to save.

 @return A promise that resolves when the account has been successfully
 saved.
*/
- (PMKPromise *)saveAccount:(ACAccount *)account;

/**
 Removes an account from the account store.

 @param account The account to remove.

 @return A promise that resolves when the account has been successfully
 removed.
*/
- (PMKPromise *)removeAccount:(ACAccount *)account;


#pragma mark Deprecated

- (PMKPromise *)promiseForAccountsWithType:(ACAccountType *)type options:(NSDictionary *)options PMK_DEPRECATED("Use -requestAccessToAccountsWithType:options:");
- (PMKPromise *)promiseForCredentialsRenewalWithAccount:(ACAccount *)account PMK_DEPRECATED("Use -renewCredentialsForAccount:");
- (PMKPromise *)promiseForAccountSave:(ACAccount *)account PMK_DEPRECATED("Use -saveAccount:");
- (PMKPromise *)promiseForAccountRemoval:(ACAccount *)account PMK_DEPRECATED("Use -removeAccount:");

@end
