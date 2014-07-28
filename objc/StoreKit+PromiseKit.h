//
//  PromiseKit+StoreKit.h
//  Aluxoft SCP
//
//  Created by Josejulio Martínez on 16/05/14.

#import "PromiseKit/fwd.h"
#import <StoreKit/SKProductsRequest.h>

@interface SKProductsRequest (PromiseKit)
- (PMKPromise *)promise;
@end
