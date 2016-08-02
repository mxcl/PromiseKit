#import <PromiseKit/Promise.h>

#if __has_include(<PromiseKit/Promise+When.h>)
#import <PromiseKit/Promise+When.h>
#endif
#if __has_include(<PromiseKit/Promise+Until.h>)
#import <PromiseKit/Promise+Until.h>
#endif
#if __has_include(<PromiseKit/Promise+Pause.h>)
#import <PromiseKit/Promise+Pause.h>
#endif
#if __has_include(<PromiseKit/Promise+Join.h>)
#import <PromiseKit/Promise+Join.h>
#endif
#if __has_include(<PromiseKit/Promise+Hang.h>)
#import <PromiseKit/Promise+Hang.h>
#endif
#if __has_include(<PromiseKit/Promise+Zalgo.h>)
#import <PromiseKit/Promise+Zalgo.h>
#endif


#ifdef PMK_ACACCOUNTSTORE
#import <PromiseKit/ACAccountStore+PromiseKit.h>
#endif
#ifdef PMK_AVAUDIOSESSION
#import <PromiseKit/AVAudioSession+PromiseKit.h>
#endif
#ifdef PMK_CLGEOCODER
#import <PromiseKit/CLGeocoder+PromiseKit.h>
#endif
#ifdef PMK_CLLOCATIONMANAGER
#import <PromiseKit/CLLocationManager+PromiseKit.h>
#endif
#ifdef PMK_CKCONTAINER
#import <PromiseKit/CKContainer+PromiseKit.h>
#endif
#ifdef PMK_CKDATABASE
#import <PromiseKit/CKDatabase+PromiseKit.h>
#endif
#ifdef PMK_MKDIRECTIONS
#import <PromiseKit/MKDirections+PromiseKit.h>
#endif
#ifdef PMK_MKMAPSNAPSHOTTER
#import <PromiseKit/MKMapSnapshotter+PromiseKit.h>
#endif
#ifdef PMK_NSFILEMANAGER
#import <PromiseKit/NSFileManager+PromiseKit.h>
#endif
#ifdef PMK_NSNOTIFICATIONCENTER
#import <PromiseKit/NSNotificationCenter+PromiseKit.h>
#endif
#ifdef PMK_NSTASK
#import <PromiseKit/NSTask+PromiseKit.h>
#endif
#ifdef PMK_NSURLCONNECTION
#import <PromiseKit/NSURLConnection+PromiseKit.h>
#endif
#ifdef PMK_SKREQUEST
#import <PromiseKit/SKRequest+PromiseKit.h>
#endif
#ifdef PMK_SLREQUEST
#import <PromiseKit/SLRequest+PromiseKit.h>
#endif
#ifdef PMK_UIACTIONSHEET
#import <PromiseKit/UIActionSheet+PromiseKit.h>
#endif
#ifdef PMK_UIALERTVIEW
#import <PromiseKit/UIAlertView+PromiseKit.h>
#endif
#ifdef PMK_UIVIEW
#import <PromiseKit/UIView+PromiseKit.h>
#endif
#ifdef PMK_UIVIEWCONTROLLER
#import <PromiseKit/UIViewController+PromiseKit.h>
#endif


#ifndef PMK_NO_UNPREFIXATION
// I used a typedef but it broke the tests, turns out typedefs are new
// types that have consequences with isKindOfClass and that
// NOTE I will remove this at 1.1
typedef PMKPromise Promise PMK_DEPRECATED("Use PMKPromise. Use of Promise is deprecated. This is a typedef, and since it is a typedef, there may be unintended side-effects.");
#endif
