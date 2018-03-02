//
//  MockNodeEnvironment.swift
//  PMKJSA+Tests
//
//  Created by Lois Di Qual on 3/1/18.
//

import Foundation
import JavaScriptCore

@available(iOS 10.0, *)
class MockNodeEnvironment {
    
    private var timers: [UInt32: Timer] = [:]
    
    static func printCurrentStackTrace() {
        
        guard let exception = JSContext.current().evaluateScript("new Error()"),
            let lineNumber = exception.objectForKeyedSubscript("line"),
            let column = exception.objectForKeyedSubscript("column"),
            let stacktrace = exception.objectForKeyedSubscript("stack").toString() else {
            return print("Couldn't get current stack trace")
        }
        
        print("At \(lineNumber):\(column)")
        
        let lines = stacktrace.split(separator: "\n").map { "\t> \($0)" }.joined(separator: "\n")
        print(lines)
    }
    
    func setup(with context: JSContext) {
        
        // console.log
        if let console = context.objectForKeyedSubscript("console") {
            let consoleLog: @convention(block) () -> Void = {
                guard let arguments = JSContext.currentArguments(), let format = arguments.first as? JSValue else {
                    return
                }
                
                let otherArguments = arguments.dropFirst()
                if otherArguments.count == 0 {
                    print(format)
                } else {
                    
                    let otherArguments = otherArguments.flatMap { $0 as? JSValue }
                    let format = format.toString().replacingOccurrences(of: "%s", with: "%@")
                    
                    // TODO: fix this format hack
                    let expectedTypes = " \(format)".split(separator: "%").dropFirst().flatMap { $0.first }.map { String($0) }
                    
                    let typedArguments = otherArguments.enumerated().flatMap { index, value -> CVarArg? in
                        let expectedType = expectedTypes[index]
                        let converted: CVarArg
                        switch expectedType {
                        case "s": converted = value.toString()
                        case "d": converted = value.toInt32()
                        case "f": converted = value.toDouble()
                        default: converted = value.toString()
                        }
                        return converted
                    }
                    
                    let output = String(format: format, arguments: typedArguments)
                    print(output)
                }
            }
            console.setObject(consoleLog, forKeyedSubscript: "log" as NSString)
            console.setObject(consoleLog, forKeyedSubscript: "error" as NSString)
        }
        
        // setTimeout
        let setTimeout: @convention(block) (JSValue, Double) -> UInt32 = { function, intervalMs in
            let timerID = self.addTimer(interval: intervalMs / 1000, repeats: false, function: function)
            return timerID
        }
        context.setObject(setTimeout, forKeyedSubscript: "setTimeout" as NSString)
        
        // clearTimeout
        let clearTimeout: @convention(block) (JSValue) -> Void = { timeoutID in
            guard timeoutID.isNumber else {
                return
            }
            self.removeTimer(timerID: timeoutID.toUInt32())
        }
        context.setObject(clearTimeout, forKeyedSubscript: "clearTimeout" as NSString)
        
        // setInterval
        let setInterval: @convention(block) (JSValue, Double) -> UInt32 = { function, intervalMs in
            let timerID = self.addTimer(interval: intervalMs / 1000, repeats: true, function: function)
            return timerID
        }
        context.setObject(setInterval, forKeyedSubscript: "setInterval" as NSString)
        
        // clearInterval
        let clearInterval: @convention(block) (JSValue) -> Void = { intervalID in
            guard intervalID.isNumber else {
                return
            }
            self.removeTimer(timerID: intervalID.toUInt32())
        }
        context.setObject(clearInterval, forKeyedSubscript: "clearInterval" as NSString)
    }
    
    private func addTimer(interval: TimeInterval, repeats: Bool, function: JSValue) -> UInt32 {
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: repeats) { _ in
            DispatchQueue.main.async {
                function.call(withArguments: [])
            }
        }
        let hash = UInt32.init(truncatingBitPattern: UUID().uuidString.hashValue)
        timers[hash] = timer
        return hash
    }
    
    private func removeTimer(timerID: UInt32) {
        guard let timer = timers[timerID] else {
            print("Cache miss: \(timerID)")
            return
        }
        timer.invalidate()
        timers[timerID] = nil
    }
}
