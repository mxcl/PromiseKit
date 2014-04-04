#define __anti_arc_retain(...) \
    void *retainedThing = (__bridge_retained void *)__VA_ARGS__; \
    retainedThing = retainedThing
#define __anti_arc_release(...) \
    void *retainedThing = (__bridge void *) __VA_ARGS__; \
    id unretainedThing = (__bridge_transfer id)retainedThing; \
    unretainedThing = nil
