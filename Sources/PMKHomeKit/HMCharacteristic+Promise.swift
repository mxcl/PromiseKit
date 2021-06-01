#if canImport(HomeKit)
#if !PMKCocoaPods
import PromiseKit
#endif
import HomeKit

public enum AccessoryError: Error {
    case incorrectType
    case serviceMissing
    case characteristicMissing
}

@available(iOS 8.0, tvOS 10.0, *)
extension HMCharacteristic {
    /**
        A simple typesafe promise wrapper around readValue
    */
    public func read<T>() -> Promise<T> {
        return Promise { seal in
            self.readValue { error in
                if let error = error { seal.reject(error) }
                else if let value = self.value as? T { seal.fulfill(value) }
                else { seal.reject(AccessoryError.incorrectType) }
            }
        }
    }
    /// Because type inference is great... until you can't compile (thanks Swift)
    public func readFloat() -> Promise<Float> { return read() }
    public func readDouble() -> Promise<Double> { return read() }
    public func readInt() -> Promise<Int> { return read() }
    public func readString() -> Promise<String> { return read() }
    
    /**
        A simple promise wrapper around writeValue
    */
    public func write(_ value: Any?) -> Promise<Void> {
        return Promise { seal in
            self.writeValue(value, completionHandler: seal.resolve)
        }
    }
    /// Explicit is good
    public func writeFloat(_ value: Float) -> Promise<Void> { return write(value) }
    public func writeDouble(_ value: Double) -> Promise<Void> { return write(value) }
    public func writeInt(_ value: Int) -> Promise<Void> { return write(value) }
    public func writeString(_ value: String) -> Promise<Void> { return write(value) }
}

#endif
