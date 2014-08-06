#import <PromiseKit/Promise.h>

#ifdef PMK_WHEN
#import <PromiseKit/Promise+When.h>
#endif
#ifdef PMK_UNTIL
#import <PromiseKit/Promise+Until.h>
#endif
#ifdef PMK_PAUSE
#import <PromiseKit/Promise+Pause.h>
#endif

#ifdef PMK_ACACCOUNTSTORE
#import <ACAccountStore+PromiseKit.h>
#endif
#ifdef PMK_AVAUDIOSESSION
#import <AVAudioSession+PromiseKit.h>
#endif
#ifdef PMK_CLGEOCODER
#import <CLGeocoder+PromiseKit.h>
#endif
#ifdef PMK_CLLOCATIONMANAGER
#import <CLLocationManager+PromiseKit.h>
#endif
#ifdef PMK_MKDIRECTIONS
#import <MKDirections+PromiseKit.h>
#endif
#ifdef PMK_MKMAPSNAPSHOTTER
#import <MKMapSnapshotter+PromiseKit.h>
#endif
#ifdef PMK_NSNOTIFICATIONCENTER
#import <NSNotificationCenter+PromiseKit.h>
#endif
#ifdef PMK_NSURLCONNECTION
#import <NSURLConnection+PromiseKit.h>
#endif
#ifdef PMK_SKPRODUCTSREQUEST
#import <SKProductsRequest+PromiseKit.h>
#endif
#ifdef PMK_SLREQUEST
#import <SLRequest+PromiseKit.h>
#endif
#ifdef PMK_UIACTIONSHEET
#import <UIActionSheet+PromiseKit.h>
#endif
#ifdef PMK_UIALERTVIEW
#import <UIAlertView+PromiseKit.h>
#endif
#ifdef PMK_UIVIEW
#import <UIView+PromiseKit.h>
#endif
#ifdef PMK_UIVIEWCONTROLLER
#import <UIViewController+PromiseKit.h>
#endif


#ifndef PMK_NO_UNPREFIXATION
// I used a typedef but it broke the tests, turns out typedefs are new
// types that have consequences with isKindOfClass and that
// NOTE I will remove this at 1.1
typedef PMKPromise Promise PMK_DEPRECATED("Use PMKPromise. Use of Promise is deprecated. This is a typedef, and since it is a typedef, there may be unintended side-effects.");
#endif
