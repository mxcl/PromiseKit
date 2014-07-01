//
//  Created by merowing on 09/05/2014.
//
//
//

#import "PromiseKit/fwd.h"

#if PMK_iOS6_ISH

#if PMK_MODULES
@import Accounts.ACAccountStore;
#else
#import <Accounts/Accounts.h>
#endif


@interface ACAccountStore (PromiseKit)
- (PMKPromise *)promiseForAccountsWithType:(ACAccountType *)type options:(NSDictionary *)options;
- (PMKPromise *)promiseForCredentialsRenewalWithAccount:(ACAccount *)account;
- (PMKPromise *)promiseForAccountSave:(ACAccount *)account;
- (PMKPromise *)promiseForAccountRemoval:(ACAccount *)account;
- (PMKPromise *)requestAccessToAccountsWithType:(ACAccountType *)type options:(NSDictionary *)options;
@end

#endif
