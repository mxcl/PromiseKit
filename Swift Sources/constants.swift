import Foundation

public let PMKErrorDomain = "PMKErrorDomain"
public let PMKURLErrorFailingDataKey = "PMKURLErrorFailingDataKey"
public let PMKURLErrorFailingStringKey = "PMKURLErrorFailingStringKey"
public let PMKURLErrorFailingURLResponseKey = "PMKURLErrorFailingURLResponseKey"
public let PMKJSONErrorJSONObjectKey = "PMKJSONErrorJSONObjectKey"

public let PMKJSONError = 1
public let NoSuchRecord = 2

#if os(OSX)
public let PMKTaskErrorStandardOutputKey = "PMKTaskErrorStandardOutputKey"
public let PMKTaskErrorStandardErrorKey = "PMKTaskErrorStandardErrorKey"
public let PMKTaskErrorExitStatusKey = "PMKTaskErrorExitStatusKey"
public let PMKTaskErrorLaunchPathKey = "PMKTaskErrorLaunchPathKey"
public let PMKTaskErrorArgumentsKey = "PMKTaskErrorArgumentsKey"

public let PMKTaskError = 3
#endif
