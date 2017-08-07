#import "PMKCallVariadicBlock.m"
#import "AnyPromise+Private.h"

NSString *const PMKErrorDomain = @"PMKErrorDomain";


@implementation AnyPromise (objc)

- (instancetype)initWithResolver:(PMKResolver __strong *)resolver {
    return [[self class] promiseWithResolverBlock:^(PMKResolver resolve){
        *resolver = resolve;
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
        return [self __alwaysOn:dispatch_get_main_queue() execute:block];
    };
}

- (AnyPromise *(^)(dispatch_queue_t, dispatch_block_t))ensureOn {
    return ^(dispatch_queue_t queue, dispatch_block_t block) {
        return [self __alwaysOn:queue execute:block];
    };
}

- (BOOL)pending {
    return [[self valueForKey:@"__pending"] boolValue];
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

- (id)value {
    id obj = [self valueForKey:@"__value"];

    if ([obj isKindOfClass:[PMKArray class]]) {
        return obj[0];
    } else {
        return obj;
    }
}

@end
