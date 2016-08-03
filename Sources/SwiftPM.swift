public enum CatchPolicy {
    case allErrorsExceptCancellation
    case allErrors
}

func PMKUnhandledErrorHandler(_ error: Error) {}

import class Dispatch.DispatchQueue

func PMKDefaultDispatchQueue() -> DispatchQueue {
    return DispatchQueue.main
}
