import class Foundation.NSThread

//TODO we only need one per thread, so instead make this
// a narrow wrapper around the data for the thread
// dictionary or something like that

class ExecutionContext {
    private var isReady = false
    private let thread = Thread.current
    private var handlers: [() -> Void] = []

    init() {
        thread.afterExecutionContext {
            self.isReady = true
            for handler in self.handlers { handler() }
        }
    }

    @inline(__always)  // keep backtrace signal-to-noise ratio sane
    func doit(_ body: @escaping () -> Void) {

        //FIXME thread-safety!

        if isReady {
            body()
        } else {
            handlers.append(body)
        }
    }
}

private let key = "org.promisekit.executionContext"

private class Fall {
    deinit {
        Thread.current.runHandlers()
    }
}

extension Thread {
    func afterExecutionContext(_ body: @escaping () -> Void) {
        if let handlers = threadDictionary[key] as? [() -> Void] {
            threadDictionary[key] = handlers + [body]
        } else {
            threadDictionary[key] = [body]

            if Thread.isMainThread {
                // the main queue always has a runloop FIXME: well in fact, no.
                // runloops are efficient for this kind of something
                // relying on autoreleasepools is less good, I think (gut feeling about how they must work in threads without runloop)
                DispatchQueue.main.async {
                    self.runHandlers()
                }
            } else {
                // runloops would be better, but there doesn't seem to be a reliable way to know
                // if the runloop for this thread (all threads have runloops) is *running*.
                // if it isn't running, we can't use it since the underlying use of this thread/queue
                // is already executing *us* and not the runloop
                // FIXME in fact, for like a command line app, the autoreleasepool may never even run
                // there is never a break in “execution context”. Jesus, maybe we should just give up. Fuck Zalgo.
                _ = Unmanaged.passRetained(Fall()).autorelease()
            }
        }
    }

    fileprivate func runHandlers() {
        assert(threadDictionary[key] != nil)
        let handlers = threadDictionary[key] as! [() -> Void]
        threadDictionary[key] = nil
        for handler in handlers {
            handler()
        }
    }
}
