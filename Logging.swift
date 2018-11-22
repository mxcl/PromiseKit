//
//  Logging.swift
//  PromiseKit
//
//  Created by Neal Lester on 11/21/18.
//

import Foundation

public enum LoggingPolicy {
    case none
    case console
    case custom((LogEvent) -> ()) // Closure provided must be thread safe
}

public enum LogEvent {
    case waitOnMainThread
    case pendingPromiseDeallocated
    case cauterized(Error)
}

public func log (_ event: PromiseKit.LogEvent) {
    loggingQueue.async() {
        activeLoggingClosure (event)
    }
}

public var loggingPolicy: LoggingPolicy = PromiseKit.LoggingPolicy.console {
    willSet (newValue) {
        loggingQueue.sync() {
            switch newValue {
            case .none:
                activeLoggingClosure = { event in }
            case .console:
                activeLoggingClosure = logConsoleClosure
            case .custom (let closure):
                activeLoggingClosure = closure
            }
        }
    }
}

public func waitOnLogging() {
    loggingQueue.sync(){}
}

private var activeLoggingClosure: (LogEvent) -> () = logConsoleClosure

private let logConsoleClosure: (LogEvent) -> () = { event in
    switch event {
    case .waitOnMainThread:
        print ("PromiseKit: warning: `wait()` called on main thread!")
    case .pendingPromiseDeallocated:
        print ("PromiseKit: warning: pending promise deallocated")
    case .cauterized (let error):
        print("PromiseKit:cauterized-error: \(error)")
    }
}

private let loggingQueue = DispatchQueue(label: "PromiseKitLogging")
