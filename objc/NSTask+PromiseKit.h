#import <Foundation/NSTask.h>
#import <PromiseKit/fwd.h>

#define PMKTaskError 1
#define PMKTaskErrorStandardOutputKey @"PMKTaskErrorStandardOutputKey"
#define PMKTaskErrorStandardErrorKey @"PMKTaskErrorStandardErrorKey"
#define PMKTaskErrorExitStatusKey @"PMKTaskErrorExitStatusKey"


@interface NSTask (PromiseKit)

/**
 Calls `-launch` and thens the stdout interpreted as a UTF8 string,
 the stderr interpreted as a UTF8 string and finally the stdout as
 NSData.

 If the task fails the promise is rejected with code `PMKTaskError`,
 and userInfo keys `PMKTaskErrorStandardOutputKey`,
 `PMKTaskErrorStandardErrorKey` and `PMKTaskErrorExitStatusKey`.
*/
- (PMKPromise *)promise;

@end
