#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import "PromiseKit.h"

static dispatch_once_t __PMKUnhandledExceptionHandlerToken;
static NSError *(^__PMKUnhandledExceptionHandler)(id);

NSError *PMKProcessUnhandledException(id thrown) {

    dispatch_once(&__PMKUnhandledExceptionHandlerToken, ^{
        __PMKUnhandledExceptionHandler = ^id(id reason){
            if ([reason isKindOfClass:[NSError class]])
                return reason;
            if ([reason isKindOfClass:[NSString class]])
                return [NSError errorWithDomain:PMKErrorDomain code:PMKUnexpectedError userInfo:@{NSLocalizedDescriptionKey: reason}];
            return nil;
        };
    });

    id err = __PMKUnhandledExceptionHandler(thrown);
    if (!err) {
        NSLog(@"PromiseKit no longer catches *all* exceptions. However you can change this behavior by setting a new PMKProcessUnhandledException handler.");
        @throw thrown;
    }
    return err;
}

void PMKSetUnhandledExceptionHandler(NSError *(^newHandler)(id)) {
    dispatch_once(&__PMKUnhandledExceptionHandlerToken, ^{
        __PMKUnhandledExceptionHandler = newHandler;
    });
}
