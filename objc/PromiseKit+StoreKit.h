//
//  PromiseKit+StoreKit.h
//  Aluxoft SCP
//
//  Created by Josejulio Martínez on 16/05/14.

#import "PromiseKit/fwd.h"

#if PMK_MODULES
  @import StoreKit.SKProductsRequest;
#else
  #import <StoreKit/StoreKit.h>
#endif

@interface SKProductsRequest (PromiseKit)
- (PMKPromise *)promise;
@end
