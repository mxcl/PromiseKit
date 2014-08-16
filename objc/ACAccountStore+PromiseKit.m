#import "ACAccountStore+PromiseKit.h"
#import "PromiseKit/Promise.h"


@implementation ACAccountStore (PromiseKit)

- (PMKPromise *)requestAccessToAccountsWithType:(ACAccountType *)type options:(NSDictionary *)options {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        [self requestAccessToAccountsWithType:type options:options completion:^(BOOL granted, NSError *error) {
            if (granted) {
                fulfiller([self accountsWithAccountType:type]);
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

- (PMKPromise *)promiseForAccountsWithType:(ACAccountType *)type options:(NSDictionary *)options {
    return [self requestAccessToAccountsWithType:type options:options];
}

- (PMKPromise *)renewCredentialsForAccount:(ACAccount *)account {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        [self renewCredentialsForAccount:account completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
            if (error) {
                rejecter(error);
            } else
                fulfiller(@(renewResult));
        }];
    }];
}

- (PMKPromise *)promiseForCredentialsRenewalWithAccount:(ACAccount *)account {
    return [self renewCredentialsForAccount:account];
}

- (PMKPromise *)saveAccount:(ACAccount *)account {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        [self saveAccount:account withCompletionHandler:^(BOOL success, NSError *error) {
            if (!success) {
                rejecter(error);
            } else
                fulfiller(nil);
        }];
    }];
}

- (PMKPromise *)promiseForAccountSave:(ACAccount *)account {
    return [self saveAccount:account];
}

- (PMKPromise *)removeAccount:(ACAccount *)account {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter) {
        [self removeAccount:account withCompletionHandler:^(BOOL success, NSError *error) {
            if (!success) {
                rejecter(error);
            } else
                fulfiller(nil);
        }];
    }];
}

- (PMKPromise *)promiseForAccountRemoval:(ACAccount *)account {
    return [self removeAccount:account];
}

@end
