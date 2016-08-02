#import "ACAccountStore+PromiseKit.h"
#import <PromiseKit/Promise.h>


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
    return [PMKPromise promiseWithIntegerAdapter:^(PMKIntegerAdapter adapter) {
        [self renewCredentialsForAccount:account completion:adapter];
    }];
}

- (PMKPromise *)promiseForCredentialsRenewalWithAccount:(ACAccount *)account {
    return [self renewCredentialsForAccount:account];
}

- (PMKPromise *)saveAccount:(ACAccount *)account {
    return [PMKPromise promiseWithBooleanAdapter:^(PMKBooleanAdapter adapter) {
        [self saveAccount:account withCompletionHandler:adapter];
    }];
}

- (PMKPromise *)promiseForAccountSave:(ACAccount *)account {
    return [self saveAccount:account];
}

- (PMKPromise *)removeAccount:(ACAccount *)account {
    return [PMKPromise promiseWithBooleanAdapter:^(PMKBooleanAdapter adapter) {
        [self removeAccount:account withCompletionHandler:adapter];
    }];
}

- (PMKPromise *)promiseForAccountRemoval:(ACAccount *)account {
    return [self removeAccount:account];
}

@end
