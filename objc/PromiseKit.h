#import <PromiseKit/Promise.h>

#ifdef PMK_CORELOCATION
#import <CoreLocation+PromiseKit.h>
#endif
#ifdef PMK_FOUNDATION
#import <Foundation+PromiseKit.h>
#endif
#if defined(PMK_UIKIT) || defined(PMK_UIANIMATION)
#import <UIKit+PromiseKit.h>
#endif
#ifdef PMK_MAPKIT
#import <MapKit+PromiseKit.h>
#endif
#ifdef PMK_SOCIAL
#import <Social+PromiseKit.h>
#endif
#ifdef PMK_STOREKIT
#import <StoreKit+PromiseKit.h>
#endif
#ifdef PMK_AVFOUNDATION
#import <AVFoundation+PromiseKit.h>
#endif
#ifdef PMK_ACCOUNTS
#import <Accounts+PromiseKit.h>
#endif
#ifdef PMK_TIMING
#import <PromiseKit/Promise+Timing.h>
#endif

#ifndef PMK_NO_UNPREFIXATION
// I used a typedef but it broke the tests, turns out typedefs are new
// types that have consequences with isKindOfClass and that
// NOTE I will remove this at 1.1
typedef PMKPromise Promise __attribute__((deprecated("Use PMKPromise. Use of Promise is deprecated. This is a typedef, and since it is a typedef, there may be unintended side-effects.")));
#endif
