#import "ACAccountStore+AnyPromise.h"
#import <PromiseKit/PromiseKit.h>


@implementation ACAccountStore (PromiseKit)

- (AnyPromise *)requestAccessToAccountsWithType:(ACAccountType *)type options:(NSDictionary *)options {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self requestAccessToAccountsWithType:type options:options completion:^(BOOL granted, NSError *error) {
            if (granted) {
                resolve([self accountsWithAccountType:type]);
            } else if (error) {
                resolve(error);
            } else {
                error = [NSError errorWithDomain:PMKErrorDomain code:PMKAccessDeniedError userInfo:@{
                    NSLocalizedDescriptionKey: @"Access to the requested social service has been denied. Please enable access in your device settings."
                }];
                resolve(error);
            }
        }];
    }];
}

- (AnyPromise *)renewCredentialsForAccount:(ACAccount *)account {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self renewCredentialsForAccount:account completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
            resolve(error ?: @(renewResult));
        }];
    }];
}

- (AnyPromise *)saveAccount:(ACAccount *)account {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self saveAccount:account withCompletionHandler:^(BOOL success, NSError *error) {
            resolve(error);
        }];
    }];
}

- (AnyPromise *)removeAccount:(ACAccount *)account {
    return [AnyPromise promiseWithResolverBlock:^(PMKResolver resolve) {
        [self removeAccount:account withCompletionHandler:^(BOOL success, NSError *error) {
            resolve(error);
        }];
    }];
}

@end
