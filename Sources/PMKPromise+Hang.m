@import CoreFoundation.CFRunLoop;
#import "PromiseKit/Promise+Hang.h"

@implementation PMKPromise (Hang)

+ (id)hang:(PMKPromise *)promise {
    if (promise.pending) {
        static CFRunLoopSourceContext context;

        CFRunLoopRef runLoop = CFRunLoopGetCurrent();
        CFRunLoopSourceRef runLoopSource = CFRunLoopSourceCreate(NULL, 0, &context);
        CFRunLoopAddSource(runLoop, runLoopSource, kCFRunLoopDefaultMode);

        promise.finally(^{
            CFRunLoopStop(runLoop);
        });
        while (promise.pending) {
            CFRunLoopRun();
        }
        CFRunLoopRemoveSource(runLoop, runLoopSource, kCFRunLoopDefaultMode);
        CFRelease(runLoopSource);
    }

    return [promise value];
}

@end
