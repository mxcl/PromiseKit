#import "assert.h"
@import Dispatch.introspection;
@import Foundation.NSDictionary;
@import Foundation.NSError;
@import Foundation.NSException;
@import Foundation.NSKeyValueCoding;
@import Foundation.NSMethodSignature;
@import Foundation.NSPointerArray;
#import "Private/NSMethodSignatureForBlock.m"
#import "PromiseKit/Promise.h"

#define NSErrorWithThrown(e) [NSError errorWithDomain:PMKErrorDomain code:PMKErrorCodeThrown userInfo:@{PMKThrown: e}]
#define IsPromise(o) ([o isKindOfClass:[Promise class]])
#define IsPending(o) (((Promise *)o)->result == nil)
#define PMKE(txt) [NSException exceptionWithName:@"PromiseKit" reason:@"PromiseKit: " txt userInfo:nil]

static const id PMKNull = @"PMKNull";

static void RejectRecursively(Promise *);
static void FulfillRecursively(Promise *);

@interface PMKArray : NSObject
@end



/**
 `then` and `catch` are method-signature tolerant, this function calls
 the block correctly and normalizes the return value to `id`.
 */
static id safely_call_block(id frock, id result) {
    if (!frock)
        @throw PMKE(@"Internal error");

    if (result == PMKNull)
        result = nil;

    @try {
        NSMethodSignature *sig = NSMethodSignatureForBlock(frock);
        const NSUInteger nargs = sig.numberOfArguments;
        const char rtype = sig.methodReturnType[0];

        #define call_block_with_rtype(type) ({^type{ \
            switch (nargs) { \
                default:  @throw PMKE(@"Invalid argument count for handler block"); \
                case 1:   return ((type(^)(void))frock)(); \
                case 2: { \
                    type (^block)(id) = frock; \
                    return [result class] == [PMKArray class] \
                        ? block(result[0]) \
                        : block(result); \
                } \
                case 3: { \
                    type (^block)(id, id) = frock; \
                    return [result class] == [PMKArray class] \
                        ? block(result[0], result[1]) \
                        : block(result, nil); \
                } \
                case 4: { \
                    type (^block)(id, id, id) = frock; \
                    return [result class] == [PMKArray class] \
                        ? block(result[0], result[1], result[2]) \
                        : block(result, nil, nil); \
                } \
            }}();})

        switch (rtype) {
            case 'v':
                call_block_with_rtype(void);
                return PMKNull;
            case '@':
                return call_block_with_rtype(id) ?: PMKNull;
            case '*': {
                char *str = call_block_with_rtype(char *);
                return str ? @(str) : PMKNull;
            }
            case 'c': return @(call_block_with_rtype(char));
            case 'i': return @(call_block_with_rtype(int));
            case 's': return @(call_block_with_rtype(short));
            case 'l': return @(call_block_with_rtype(long));
            case 'q': return @(call_block_with_rtype(long long));
            case 'C': return @(call_block_with_rtype(unsigned char));
            case 'I': return @(call_block_with_rtype(unsigned int));
            case 'S': return @(call_block_with_rtype(unsigned short));
            case 'L': return @(call_block_with_rtype(unsigned long));
            case 'Q': return @(call_block_with_rtype(unsigned long long));
            case 'f': return @(call_block_with_rtype(float));
            case 'd': return @(call_block_with_rtype(double));
            case 'B': return @(call_block_with_rtype(_Bool));
            case '^':
                if (strcmp(sig.methodReturnType, "^v") == 0) {
                    call_block_with_rtype(void);
                    return PMKNull;
                }
                // else fall through!
            default:
                @throw PMKE(@"Unsupported method signature… Why not fork and fix?");
        }
    } @catch (id e) {
        return [e isKindOfClass:[NSError class]] ? e : NSErrorWithThrown(e);
    }
}



/**
 We have public @implementation instance variables so ResolveRecursively
 and RejectRecursively can fulfill promises. It’s like the C++ `friend`
 keyword.
 */
@implementation Promise {
@public
    NSMutableArray *pendingPromises;
    NSMutableArray *thens;
    NSMutableArray *fails;
    id result;
}

- (instancetype)init {
    thens = [NSMutableArray new];
    fails = [NSMutableArray new];
    pendingPromises = [NSMutableArray new];
    return self;
}

- (Promise *(^)(id))then {
    if ([result isKindOfClass:[Promise class]])
        return ((Promise *)result).then;

    if ([result isKindOfClass:[NSError class]])
        return ^(id block) {
            return [Promise promiseWithValue:result];
        };

    if (result) return ^id(id block) {
        id rv = safely_call_block(block, result);
        if ([rv isKindOfClass:[Promise class]])
            return rv;
        return [Promise promiseWithValue:rv];
    };

    return ^(id block) {
        Promise *next = [Promise new];
        [pendingPromises addObject:next];
        // avoiding retain cycle by passing self->result as block parameter
        [thens addObject:^(id selfDotResult){
            next->result = safely_call_block(block, selfDotResult);
            return next;
        }];
        return next;
    };
}

- (Promise *(^)(id))catch {
    if ([result isKindOfClass:[Promise class]])
        return ((Promise *)result).catch;

    if (result && ![result isKindOfClass:[NSError class]])
        return ^(id block){
            return [Promise promiseWithValue:result];
        };

    if (result) return ^id(id block){
        id rv = safely_call_block(block, result);
        return [rv isKindOfClass:[Promise class]]
             ? rv
             : [Promise promiseWithValue:rv];
    };

    return ^(id block) {
        Promise *next = [Promise new];
        [pendingPromises addObject:next];
        // avoiding retain cycle by passing self->result as block parameter
        [fails addObject:^(id selfDotResult){
            next->result = safely_call_block(block, selfDotResult);
            return next;
        }];
        return next;
    };
}

+ (Promise *)all:(id<NSFastEnumeration>)promises {
    NSFastEnumerationState unused = {0};
    __block NSUInteger count = [promises countByEnumeratingWithState:&unused objects:NULL count:0];

    NSPointerArray *results = [NSPointerArray strongObjectsPointerArray];
    results.count = count;

    return [Promise new:^(void(^fulfiller)(id), void(^rejecter)(id)){        
        NSUInteger ii = 0;
        for (__strong Promise *promise in promises) {
            if (!IsPromise(promise))
                promise = [Promise promiseWithValue:promise];

            promise.catch(rejecter);
            promise.then(^(id o){
                [results replacePointerAtIndex:ii withPointer:(__bridge void *)(o ?: PMKNull)];
                if (--count == 0) {
                    for (NSUInteger y = 0; y < results.count; ++y)
                        if ([results pointerAtIndex:y] == (__bridge void *)PMKNull)
                            [results replacePointerAtIndex:y withPointer:(void *)kCFNull];

                    fulfiller(results.allObjects);
                }
            });
            ++ii;
        };
    }];
}

+ (Promise *)when:(id)promises {
    if ([promises conformsToProtocol:@protocol(NSFastEnumeration)]) {
        return [self all:promises];
    } else {
        return [self all:@[promises]].then(^(NSArray *values){
            return values[0];
        });
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
+ (Promise *)until:(id (^)(void))blockReturningPromises catch:(id)failHandler
{
    return [Promise new:^(void(^fulfiller)(id), id rejecter){
        __block void (^block)() = ^{
            id promises = blockReturningPromises();
            [self when:promises].then(^(id o){
                fulfiller(o);
                block = nil;  // break retain cycle
            }).catch(^(id e){
                Promise *rv = safely_call_block(failHandler, e);
                if ([rv isKindOfClass:[Promise class]])
                    rv.then(block);
                else if (![rv isKindOfClass:[NSError class]])
                    block();
            });
        };
        block();
    }];
}
#pragma clang diagnostic pop

+ (Promise *)promiseWithValue:(id)value {
    Promise *p = [Promise new];
    p->result = value ?: PMKNull;
    return p;
}

+ (Promise *)new:(void(^)(PromiseResolver, PromiseResolver))block {
    Promise *promise = [Promise new];

    id fulfiller = ^(id value){
        if (promise->result)
            return NSLog(@"PromiseKit: Promise already resolved");
        if ([value isKindOfClass:[NSError class]])
            @throw PMKE(@"You may not fulfill a Promise with an NSError");
        if (!value)
            value = PMKNull;

        if (IsPromise(value)) {
            Promise *rsvp = (Promise *)value;
            Promise *next = promise;
            if (IsPending(rsvp)) {
                [rsvp->thens addObject:^(id o){
                    next->result = o;
                    return next;
                }];
                [rsvp->pendingPromises addObject:next];
                return;
            } else
                promise->result = rsvp->result;
        } else
            promise->result = value;

        FulfillRecursively(promise);
    };
    id rejecter = ^(id error){
        if (promise->result)
            return NSLog(@"PromiseKit: Promise already resolved");
        if ([error isKindOfClass:[Promise class]])
            @throw PMKE(@"You may not reject a Promise with a Promise");
        if (!error)
            error = [NSError errorWithDomain:PMKErrorDomain code:PMKErrorCodeUnknown userInfo:nil];
        if (![error isKindOfClass:[NSError class]])
            error = NSErrorWithThrown(error);

        NSLog(@"PromiseKit: %@", error);  // we refuse to let errors die silently

        promise->result = error;
        RejectRecursively(promise);
    };

    @try {
        block(fulfiller, rejecter);
    } @catch (id e) {
        promise->result = [e isKindOfClass:[NSError class]] ? e : NSErrorWithThrown(e);
    }

    return promise;
}

- (BOOL)pending {
    if (IsPromise(result)) {
        return [result pending];
    } else
        return result == nil;
}

- (BOOL)resolved {
    return result != nil;
}

- (BOOL)fulfilled {
    return self.resolved && ![result isKindOfClass:[NSError class]];
}

- (BOOL)rejected {
    return self.resolved && [result isKindOfClass:[NSError class]];
}

- (id)value {
    if (IsPromise(result))
        return [(Promise*)result value];
    if (result == PMKNull)
        return nil;
    else
        return result;
}

@end


/**
 Static C functions rather that methods on Promise to enforce strict
 encapsulation and immutability on Promise objects. This may seem strict,
 but it fits well with the ideals of the Promise pattern. You can be
 completely certain that third-party libraries and end-users of your
 Promise based API did not modify your Promises.
 */
static void FulfillRecursively(Promise *promise) {
    assert(promise.fulfilled);

    for (id (^then)(id) in promise->thens) {
        Promise *next = then(promise->result);
        [promise->pendingPromises removeObject:next];

        // next was resolved in the then block

        if ([next->result isKindOfClass:[NSError class]])
            RejectRecursively(next);
        else if (IsPromise(next->result) && IsPending(next->result)) {
            Promise *rsvp = next->result;
            [rsvp->thens addObject:^(id o){
                next->result = o;
                return next;
            }];
            [rsvp->pendingPromises addObject:next];
        }
        else if (IsPromise(next->result) && !IsPending(next->result)) {
            next->result = ((Promise *)next->result)->result;
            FulfillRecursively(next);
        } else
            FulfillRecursively(next);
    }

    // search through fails for thens
    for (Promise *pending in promise->pendingPromises) {
        pending->result = promise->result;
        FulfillRecursively(pending);
    }

    promise->thens = promise->fails = promise->pendingPromises = nil;
}

static void RejectRecursively(Promise *promise) {
    assert(promise.rejected);

    for (id (^fail)(id) in promise->fails) {
        Promise *next = fail(promise->result);
        [promise->pendingPromises removeObject:next];

        // next was resolved in the catch block

        if (IsPromise(next->result) && IsPending(next->result)) {
            Promise *rsvp = next->result;
            [rsvp->thens addObject:^(id o){
                next->result = o;
                return next;
            }];
            [rsvp->pendingPromises addObject:next];
            continue;
        }
        if (IsPromise(next->result) && !IsPending(next->result))
            next->result = ((Promise *)next->result)->result;

        if (next->result == PMKNull)
            // we're done
            continue;
        if ([next->result isKindOfClass:[NSError class]])
            // bubble again!
            RejectRecursively(next);
        else
            FulfillRecursively(next);
    }

    // search through thens for fails
    for (Promise *pending in promise->pendingPromises) {
        pending->result = promise->result;
        RejectRecursively(pending);
    }

    promise->thens = promise->fails = promise->pendingPromises = nil;
}



Promise *dispatch_promise(id block) {
    return dispatch_promise_on(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

Promise *dispatch_promise_on(dispatch_queue_t queue, id block) {
    return [Promise new:^(void(^fulfiller)(id), void(^rejecter)(id)){
        dispatch_async(queue, ^{
            __block id result = safely_call_block(block, nil);
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([result isKindOfClass:[NSError class]])
                    rejecter(result);
                else
                    fulfiller(result);
            });
        });
    }];
}



@implementation PMKArray
{ @public NSArray *objs; }

- (id)objectAtIndexedSubscript:(NSUInteger)idx {
    return objs.count >= idx+1 ? objs[idx] : nil;
}

@end



#undef PMKManifold

id PMKManifold(NSArray *args) {
    PMKArray *aa = [PMKArray new];
    aa->objs = args;
    return aa;
}
