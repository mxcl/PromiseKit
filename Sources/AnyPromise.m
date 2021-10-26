#import "PMKCallVariadicBlock.m"
#import "AnyPromise+Private.h"
#import "AnyPromise.h"


NSString *const PMKErrorDomain = @"PMKErrorDomain";


@implementation AnyPromise (ObjC)

- (instancetype)initWithResolver:(PMKResolver __strong *)resolver {
    self = [self initWithResolver_:^(void (^resolve)(id)) {
            *resolver = resolve;
    }];
    return self;
}

+ (instancetype)promiseWithResolverBlock:(void (^)(PMKResolver _Nonnull))resolveBlock {
    return [[AnyPromise alloc] initWithResolver_:resolveBlock];
}

+ (instancetype)promiseWithValue:(id)value {
    //TODO provide a more efficient route for sealed promises
    return [[AnyPromise alloc] initWithResolver_:^(void (^resolve)(id)) {
        resolve(value);
    }];
}

- (AnyPromise *(^)(id))then {
    return ^(id block) {
        return [self __thenOn:dispatch_get_main_queue() execute:^(id obj) {
            return PMKCallVariadicBlock(block, obj);
        }];
    };
}

- (AnyPromise *(^)(dispatch_queue_t, id))thenOn {
    return ^(dispatch_queue_t queue, id block) {
        return [self __thenOn:queue execute:^(id obj) {
            return PMKCallVariadicBlock(block, obj);
        }];
    };
}

- (AnyPromise *(^)(id))thenInBackground {
    return ^(id block) {
        return [self __thenOn:dispatch_get_global_queue(0, 0) execute:^(id obj) {
            return PMKCallVariadicBlock(block, obj);
        }];
    };
}

- (AnyPromise *(^)(dispatch_queue_t, id))catchOn {
    return ^(dispatch_queue_t q, id block) {
        return [self __catchOn:q execute:^(id obj) {
            return PMKCallVariadicBlock(block, obj);
        }];
    };
}

- (AnyPromise *(^)(id))catch {
    return ^(id block) {
        return [self __catchOn:dispatch_get_main_queue() execute:^(id obj) {
            return PMKCallVariadicBlock(block, obj);
        }];
    };
}

- (AnyPromise *(^)(id))catchInBackground {
    return ^(id block) {
        return [self __catchOn:dispatch_get_global_queue(0, 0) execute:^(id obj) {
            return PMKCallVariadicBlock(block, obj);
        }];
    };
}

- (AnyPromise *(^)(dispatch_block_t))ensure {
    return ^(dispatch_block_t block) {
        return [self __ensureOn:dispatch_get_main_queue() execute:block];
    };
}

- (AnyPromise *(^)(dispatch_queue_t, dispatch_block_t))ensureOn {
    return ^(dispatch_queue_t queue, dispatch_block_t block) {
        return [self __ensureOn:queue execute:block];
    };
}

- (id)wait {
    return [self __wait];
}

- (BOOL)pending {
    return [[self valueForKey:@"__pending"] boolValue];
}

- (BOOL)rejected {
    return IsError([self __value]);
}

- (BOOL)fulfilled {
    return !self.rejected;
}

- (id)value {
    id obj = [self __value];

    if ([obj isKindOfClass:[PMKArray class]]) {
        return obj[0];
    } else {
        return obj;
    }
}

@end



@implementation AnyPromise (Adapters)

+ (instancetype)promiseWithAdapterBlock:(void (^)(PMKAdapter))block {
    return [self promiseWithResolverBlock:^(PMKResolver resolve) {
        block(^(id value, id error){
            resolve(error ?: value);
        });
    }];
}

+ (instancetype)promiseWithIntegerAdapterBlock:(void (^)(PMKIntegerAdapter))block {
    return [self promiseWithResolverBlock:^(PMKResolver resolve) {
        block(^(NSInteger value, id error){
            if (error) {
                resolve(error);
            } else {
                resolve(@(value));
            }
        });
    }];
}

+ (instancetype)promiseWithBooleanAdapterBlock:(void (^)(PMKBooleanAdapter adapter))block {
    return [self promiseWithResolverBlock:^(PMKResolver resolve) {
        block(^(BOOL value, id error){
            if (error) {
                resolve(error);
            } else {
                resolve(@(value));
            }
        });
    }];
}

@end
