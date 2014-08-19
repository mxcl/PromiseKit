#import "PromiseKit/Promise.h"
#import "NSTask+PromiseKit.h"

@implementation NSTask (PromiseKit)

- (PMKPromise *)promise {
    self.standardOutput = [NSPipe pipe];
    self.standardError = [NSPipe pipe];
    [self launch];

    return dispatch_promise(^id{
        [self waitUntilExit];

        id stdoutData = [[self.standardOutput fileHandleForReading] readDataToEndOfFile];
        id stdoutString = [[NSString alloc] initWithData:stdoutData encoding:NSUTF8StringEncoding];
        id stderrData = [[self.standardError fileHandleForReading] readDataToEndOfFile];
        id stderrString = [[NSString alloc] initWithData:stderrData encoding:NSUTF8StringEncoding];

        if (self.terminationReason == NSTaskTerminationReasonExit) {
            return PMKManifold(stdoutString, stderrString, stdoutData);
        } else {
            id cmd = [NSMutableArray arrayWithObject:self.launchPath];
            [cmd addObjectsFromArray:self.arguments];
            cmd = [cmd componentsJoinedByString:@" "];

            id info = @{
                NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Failed executing: %@.", cmd],
                PMKTaskErrorStandardOutputKey: stdoutString,
                PMKTaskErrorStandardErrorKey: stderrString,
                PMKTaskErrorExitStatusKey: @(self.terminationStatus),
            };

            return [NSError errorWithDomain:PMKErrorDomain code:PMKTaskError userInfo:info];
        }
    });
}

@end
