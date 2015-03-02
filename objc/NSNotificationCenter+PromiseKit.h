#import <Foundation/NSNotification.h>
#import <PromiseKit/fwd.h>


/**
 To import the `NSNotificationCenter` category:

    pod "PromiseKit/NSNotificationCenter"

 Or you can import all categories on `Foundation`:

    pod "PromiseKit/Foundation"

 Or `NSNotificationCenter` is one of the categories imported by the umbrella pod:

    pod "PromiseKit"
*/
@interface NSNotificationCenter (PromiseKit)
/**
 Observe the named notification once.

 @warning *Important* Promises only resolve once. If you need your block to execute more than once then use `-addObserverForName:object:queue:usingBlock:`.

 @param notificationName The name of the notification for which to register the observer.
 
 @returns A promise that fulfills with two parameters: 
 1. The NSNotification object.
 2. The NSNotification’s userInfo property.
*/
+ (PMKPromise *)once:(NSString *)notificationName;
@end
