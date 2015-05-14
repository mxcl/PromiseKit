#import <arpa/inet.h>
#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <PromiseKit/AnyPromise.h>
#import <sys/socket.h>
#import <SystemConfiguration/SystemConfiguration.h>

@interface JTSReachability: NSObject {
@public
    PMKResolver resolve;
    id retainCycle;
}
- (BOOL)reachable;
- (void)start;
@end


AnyPromise *SCNetworkReachability() {
    JTSReachability *reach = [JTSReachability new];
    if (reach.reachable)
        return [AnyPromise promiseWithValue:nil];
    reach->retainCycle = reach;
    [reach start];
    return [[AnyPromise alloc] initWithResolver:&reach->resolve];
}


static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info) {
    JTSReachability *reachability = (__bridge JTSReachability *)info;
    if (reachability.reachable) {
        reachability->resolve(nil);
        reachability->retainCycle = nil;
    }
}


@implementation JTSReachability {
    SCNetworkReachabilityRef reachabilityRef;
}

- (instancetype)init {
	struct sockaddr_in zeroAddress;
	bzero(&zeroAddress, sizeof(zeroAddress));
	zeroAddress.sin_len = sizeof(zeroAddress);
	zeroAddress.sin_family = AF_INET;

    reachabilityRef = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)&zeroAddress);

    return self;
}

- (void)start {
    SCNetworkReachabilityContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
    SCNetworkReachabilitySetCallback(reachabilityRef, ReachabilityCallback, &context);
    SCNetworkReachabilityScheduleWithRunLoop(reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
}

- (void)dealloc {
    SCNetworkReachabilityUnscheduleFromRunLoop(reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    CFRelease(reachabilityRef);
}

- (BOOL)reachable {
	SCNetworkReachabilityFlags flags;
	if (!SCNetworkReachabilityGetFlags(reachabilityRef, &flags))
        return NO;

    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)
        return NO;

    BOOL returnValue = NO;

    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
    {
        /*
         If the target host is reachable and no connection is required then we'll assume (for now) that you're on Wi-Fi...
         */
        returnValue = YES;
    }

    if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
         (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
    {
        /*
         ... and the connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs...
         */

        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
        {
            /*
             ... and no [user] intervention is needed...
             */
            returnValue = YES;
        }
    }

#if TARGET_OS_IPHONE
    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
    {
        /*
         ... but WWAN connections are OK if the calling application is using the CFNetwork APIs.
         */
        if (flags & kSCNetworkReachabilityFlagsConnectionRequired) {
            returnValue = NO;
        } else {
            returnValue = YES;
        }
    }
#endif

	return returnValue;
}

@end
