//
//  Created by merowing on 09/05/2014.
//
//
//

#import <PromiseKit/AnyPromise.h>
#import <Accounts/ACAccountStore.h>

/**
 To import the `ACAccountStore` category:

    use_frameworks!
    pod "PromiseKit/Accounts"
 
 And then in your sources:

    #import <PromiseKit/PromiseKit.h>
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
- (AnyPromise *)requestAccessToAccountsWithType:(ACAccountType *)type options:(NSDictionary *)options;

/**
 Renews account credentials when the credentials are no longer valid.

 @param account The account to renew credentials.

 @return A promise that thens the `ACAccountCredentialRenewResult`.
*/
- (AnyPromise *)renewCredentialsForAccount:(ACAccount *)account;

/**
 Saves an account to the Accounts database.

 @param account The account to save.

 @return A promise that resolves when the account has been successfully
 saved.
*/
- (AnyPromise *)saveAccount:(ACAccount *)account;

/**
 Removes an account from the account store.

 @param account The account to remove.

 @return A promise that resolves when the account has been successfully
 removed.
*/
- (AnyPromise *)removeAccount:(ACAccount *)account;

@end
