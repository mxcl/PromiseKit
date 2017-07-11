public enum CatchPolicy {
    case allErrorsExceptCancellation
    case allErrors
}

func PMKUnhandledErrorHandler(_ error: Error)
{}
