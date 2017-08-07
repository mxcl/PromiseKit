import Dispatch

public struct PMKConfiguration {
    /// the default queues that promises handlers dispatch to
    public var Q = (map: DispatchQueue.main, return: DispatchQueue.main)

    public var catchPolicy = CatchPolicy.allErrorsExceptCancellation
}

//TODO disallow modification of this after first promise instantiation
//TODO this should be per module too, eg. frameworks you use that provide promises
//     should be confident about the queues their code runs on
public var conf = PMKConfiguration()
