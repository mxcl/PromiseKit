//
//  PromiseKit+StoreKit.m
//  Aluxoft SCP
//
//  Created by Josejulio Martínez on 16/05/14.
//

#import "SKRequest+AnyPromise.h"
#import <StoreKit/SKProductsRequest.h>

//TODO do categories work on inherited classes? As would solve our swift SKProductsRequest problem

@interface PMKSKRequestDelegate : NSObject <SKProductsRequestDelegate> {
@public
    PMKResolver resolve;
    id retainCycle;
}
@end

@implementation PMKSKRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    resolve(response);
    retainCycle = request.delegate = nil;
}

- (void)requestDidFinish:(SKRequest *)request {
    resolve(nil);
    retainCycle = request.delegate = nil;
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    resolve(error);
    retainCycle = request.delegate = nil;
}

@end

@implementation SKProductsRequest (PromiseKit)

- (AnyPromise *)promise {
    PMKSKRequestDelegate *d = [PMKSKRequestDelegate new];
    d->retainCycle = self.delegate = d;
    [self start];
    return [[AnyPromise alloc] initWithResolver:&d->resolve];
}

@end
