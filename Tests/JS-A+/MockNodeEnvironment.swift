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
    
    private var timers: [Int: Timer] = [:]
    
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
        }
        
        // setTimeout
        let setTimeout: @convention(block) (JSValue, Double) -> Int = { function, intervalMs in
            let timerID = self.addTimer(interval: intervalMs / 1000, repeats: false, function: function)
            return timerID
        }
        context.setObject(setTimeout, forKeyedSubscript: "setTimeout" as NSString)
        
        // clearTimeout
        let clearTimeout: @convention(block) (Int) -> Void = { timeoutID in
            self.removeTimer(timerID: timeoutID)
        }
        context.setObject(clearTimeout, forKeyedSubscript: "clearTimeout" as NSString)
        
        // setInterval
        let setInterval: @convention(block) (JSValue, Double) -> Int = { function, intervalMs in
            let timerID = self.addTimer(interval: intervalMs / 1000, repeats: true, function: function)
            return timerID
        }
        context.setObject(setInterval, forKeyedSubscript: "setInterval" as NSString)
        
        // clearInterval
        let clearInterval: @convention(block) (Int) -> Void = { intervalID in
            self.removeTimer(timerID: intervalID)
        }
        context.setObject(clearInterval, forKeyedSubscript: "clearInterval" as NSString)
    }
    
    private func addTimer(interval: TimeInterval, repeats: Bool, function: JSValue) -> Int {
        let hash = UUID().uuidString.hash
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            DispatchQueue.main.async {
                function.call(withArguments: [])
            }
        }
        timers[hash] = timer
        return hash
    }
    
    private func removeTimer(timerID: Int) {
        timers[timerID]?.invalidate()
        timers[timerID] = nil
    }
}
