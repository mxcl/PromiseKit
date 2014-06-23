#import "PromiseKit+Accounts.h"
#import "PromiseKit/Promise.h"

#if PMK_iOS6_ISH

@implementation ACAccountStore (PromiseKit)

- (PMKPromise *)requestAccessToAccountsWithType:(ACAccountType *)type options:(NSDictionary *)options {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        [self requestAccessToAccountsWithType:type options:options completion:^(BOOL granted, NSError *error) {
            if (granted) {
                fulfiller(self);
            } else if (error) {
                rejecter(error);
            } else {
                error = [NSError errorWithDomain:PMKErrorDomain code:PMKAccessDeniedError userInfo:@{
                    NSLocalizedDescriptionKey: @"Access to the requested social service has been denied. Please enable access in your device settings."
                }];
                rejecter(error);
            }
        }];
    }];
}

- (PMKPromise *)promiseForAccountsWithType:(ACAccountType *)type options:(NSDictionary *)options
{
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        [self requestAccessToAccountsWithType:type options:options completion:^(BOOL granted, NSError *error) {
            if (!granted) {
                rejecter(error);
            } else
                fulfiller([self accountsWithAccountType:type]);
        }];
    }];
}

- (PMKPromise *)promiseForCredentialsRenewalWithAccount:(ACAccount *)account
{
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        [self renewCredentialsForAccount:account completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
            if (error) {
                rejecter(error);
            } else
                fulfiller(@(renewResult));
        }];
    }];
}

- (PMKPromise *)promiseForAccountSave:(ACAccount *)account
{
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        [self saveAccount:account withCompletionHandler:^(BOOL success, NSError *error) {
            if (!success) {
                rejecter(error);
            } else
                fulfiller(nil);
        }];
    }];
}

- (PMKPromise *)promiseForAccountRemoval:(ACAccount *)account
{
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        [self removeAccount:account withCompletionHandler:^(BOOL success, NSError *error) {
            if (!success) {
                rejecter(error);
            } else
                fulfiller(nil);
        }];
    }];
}

@end

#endif
