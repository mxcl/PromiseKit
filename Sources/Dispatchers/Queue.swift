import Foundation

// Simple queue implementation with storage recovery

fileprivate let arraySizeWorthCompacting = 100
fileprivate let minUtilization = 0.6

struct Queue<T> {
    
    var elements: [T?] = []
    var head = 0
    let maxDepth: Int?
    
    init(maxDepth: Int? = nil) {
        self.maxDepth = maxDepth
    }
    
    var isEmpty: Bool {
        return head >= elements.count
    }
    
    var count: Int {
        return elements.count - head
    }
    
    mutating func enqueue(_ item: T) {
        elements.append(item)
        if let maxDepth = maxDepth, count > maxDepth {
            _ = dequeue()
        }
    }
    
    mutating func dequeue() -> T {
        assert(!isEmpty, "Dequeue attempt on an empty Queue")
        defer {
            elements[head] = nil
            head += 1
            maybeCompactStorage()
        }
        return elements[head]!
    }
    
    private mutating func maybeCompactStorage() {
        let n = elements.count
        if n > arraySizeWorthCompacting && head > Int(Double(n) * (1 - minUtilization)) {
            compactStorage()
        }
    }
    
    mutating func compactStorage() {
        if isEmpty {
            elements.removeAll(keepingCapacity: false)
        } else {
            elements.removeFirst(head)
        }
        head = 0
    }
    
    mutating func purge() {
        elements.removeAll(keepingCapacity: false)
        head = 0
    }
    
}
