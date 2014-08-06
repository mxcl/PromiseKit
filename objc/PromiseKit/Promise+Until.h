#import <PromiseKit/Promise.h>


@interface PMKPromise (Until)
/**
Loops until one or more promises have resolved.

Because Promises are single-shot, the block to until must return one or more promises. They are then `when`’d. If they succeed the until loop is concluded. If they fail then the @param `catch` handler is executed.

If the `catch` throws or returns an `NSError` then the loop is ended.

If the `catch` handler returns a Promise then re-execution of the loop is suspended upon resolution of that Promise. If the Promise succeeds then the loop continues. If it fails the loop ends.

An example usage is an app starting up that must get data from the Internet before the main ViewController can be shown. You can `until` the poll Promise and in the catch handler decide if the poll should be reattempted or not, perhaps returning a `UIAlertView.promise` allowing the user to choose if they continue or not.
*/
+ (PMKPromise *)until:(id(^)(void))blockReturningPromiseOrArrayOfPromises catch:(id)catchHandler;

@end
