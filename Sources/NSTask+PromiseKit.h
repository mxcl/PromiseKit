#import <Foundation/NSTask.h>
#import <PromiseKit/fwd.h>

#define PMKTaskError 1
#define PMKTaskErrorStandardOutputKey @"PMKTaskErrorStandardOutputKey"
#define PMKTaskErrorStandardErrorKey @"PMKTaskErrorStandardErrorKey"
#define PMKTaskErrorExitStatusKey @"PMKTaskErrorExitStatusKey"


/**
 To import the `NSTask` category:

    pod "PromiseKit/NSTask"

 Or you can import all categories on `Foundation`:

    pod "PromiseKit/Foundation"

 Or `NSTask` is one of the categories imported by the umbrella pod:

    pod "PromiseKit"
*/
@interface NSTask (PromiseKit)

/**
 Launches the receiver and resolves when it exits.

 If the task fails the promise is rejected with code `PMKTaskError`,
 and userInfo keys `PMKTaskErrorStandardOutputKey`,
 `PMKTaskErrorStandardErrorKey` and `PMKTaskErrorExitStatusKey`.

 @return A promise that fulfills with three parameters:
 1) The stdout interpreted as a UTF8 string.
 2) The stderr interpreted as a UTF8 string.
 3) The stdout as `NSData`.
*/
- (PMKPromise *)promise;

@end
