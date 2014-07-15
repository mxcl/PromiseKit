#import "PromiseKit/Promise.h"
#ifdef PMK_CORELOCATION
#import "PromiseKit+CoreLocation.h"
#endif
#ifdef PMK_FOUNDATION
#import "PromiseKit+Foundation.h"
#endif
#ifdef PMK_UIKIT
#import "PromiseKit+UIKit.h"
#endif
#ifdef PMK_UIANIMATION
#import "PromiseKit+UIAnimation.h"
#endif
#ifdef PMK_MAPKIT
#import "PromiseKit+MapKit.h"
#endif
#ifdef PMK_SOCIAL
#import "PromiseKit+Social.h"
#endif
#ifdef PMK_STOREKIT
#import "PromiseKit+StoreKit.h"
#endif
#ifdef PMK_AVFOUNDATION
#import "PromiseKit+AVFoundation.h"
#endif
#ifdef PMK_ACCOUNTS
#import "PromiseKit+Accounts.h"
#endif
#ifdef PMK_TIMING
#import "PromiseKit/Promise+Timing.h"
#endif

#ifndef PMK_NO_UNPREFIXATION
// I used a typedef but it broke the tests, turns out typedefs are new
// types that have consequences with isKindOfClass and that
// NOTE I will remove this at 1.0
typedef PMKPromise Promise __attribute__((deprecated("Use PMKPromise. Use of Promise is deprecated. This is a typedef, and since it is a typedef, there may be unintended side-effects.")));
#endif
