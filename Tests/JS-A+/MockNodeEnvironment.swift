//
//  MockNodeEnvironment.swift
//  PMKJSA+Tests
//
//  Created by Lois Di Qual on 3/1/18.
//

import Foundation
import JavaScriptCore

class MockNodeEnvironment {
    
    private var timers: [UInt32: Timer] = [:]
    
    func setup(with context: JSContext) {
        
        // console.log / console.error
        setupConsole(context: context)
        
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
    
    private func setupConsole(context: JSContext) {
        
        guard let console = context.objectForKeyedSubscript("console") else {
            fatalError("Couldn't get global `console` object")
        }
        
        let consoleLog: @convention(block) () -> Void = {
            guard let arguments = JSContext.currentArguments(), let format = arguments.first as? JSValue else {
                return
            }
            
            // If we only have one argument, print it
            let otherArguments = arguments.dropFirst()
            guard otherArguments.count > 0 else {
                return print(format)
            }
            
            // If we have more than one argument, first argument is a string format
            // and following arguments are values to match the specifiers
            let swiftFormat = format.toString()
                .replacingOccurrences(of: "%s", with: "%@")
                .replacingOccurrences(of: "%%", with: "%@")
            let typedArguments = otherArguments.flatMap { ($0 as? JSValue)?.toObject() as? CVarArg }
            let output = String(format: swiftFormat, arguments: typedArguments)
            print(output)
        }
        console.setObject(consoleLog, forKeyedSubscript: "log" as NSString)
        console.setObject(consoleLog, forKeyedSubscript: "error" as NSString)
    }
    
    private func addTimer(interval: TimeInterval, repeats: Bool, function: JSValue) -> UInt32 {
        let block = BlockOperation {
            DispatchQueue.main.async {
                function.call(withArguments: [])
            }
        }
        let timer = Timer.scheduledTimer(timeInterval: interval, target: block, selector: #selector(Operation.main), userInfo: nil, repeats: repeats)
        let rawHash = UUID().uuidString.hashValue
    #if swift(>=4.0)
        let hash = UInt32(truncatingIfNeeded: rawHash)
    #else
        let hash = UInt32(truncatingBitPattern: rawHash)
    #endif
        timers[hash] = timer
        return hash
    }
    
    private func removeTimer(timerID: UInt32) {
        guard let timer = timers[timerID] else {
            return print("Couldn't find timer \(timerID)")
        }
        timer.invalidate()
        timers[timerID] = nil
    }
}
