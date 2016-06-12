import Foundation.NSProgress

/**
 * Resolves promises with limit of concurrently executed promises.
 *
 * let queue = new PromiseQueue(maxPendingPromises: 2, maxQueuedPromises: 4);
 *
 * queue.add({
 *     // resolve of this promise will resume next request
 *     return downloadTarballFromGithub(url, file);
 * })
 * .then { file in
 *     doStuffWith(file)
 * }
 *
 * queue.add({
 *     return downloadTarballFromGithub(url, file)
 * })
 * // This request will be paused
 * .then { file in
 *     doStuffWith(file)
 * }
 */

public class PromiseQueue<T> {

    public let maxPendingPromises: Int
    public let maxQueuedPromises: Int

    private var pendingPromises: Int = 0
    private var queue: [(generator: () throws -> Promise<T>, fulfill: (T) -> Void, reject: (ErrorType) -> Void)] = []

    public init(maxPendingPromises: Int = 1, maxQueuedPromises: Int = Int.max) {
        self.maxPendingPromises = maxPendingPromises
        self.maxQueuedPromises = maxQueuedPromises
    }

    public func add(generator: () throws -> Promise<T>) -> Promise<T> {
        guard self.queue.count <= self.maxQueuedPromises else {
            return Promise(error: NSError(domain: "sdsd", code: 1, userInfo: nil))
        }

        return Promise { fulfill, reject in
            self.queue.append((
                generator: generator,
                fulfill: fulfill,
                reject: reject
            ))

            self.dequeue()
        }
    }

    private func dequeue() {
        guard self.pendingPromises < self.maxPendingPromises else {
            return
        }

        guard self.queue.count > 0 else {
            return
        }

        let item = self.queue.removeFirst()

        self.pendingPromises += 1

        let promise: Promise<T>
        do {
            promise = try item.generator()
        }
        catch (let error) {
            self.pendingPromises -= 1
            item.reject(error)
            self.dequeue()
            return
        }

        promise
            .always {
                self.pendingPromises -= 1
            }
            .then { value -> Void in
                item.fulfill(value)
            }
            .recover { error in
                item.reject(error)
            }
            .always {
                self.dequeue()
            }
    }
}


/**
 Wait for all promises in a set (witch constructed by `generator` for all of `items`) with limit of concurrently executed ones.

 For example:
 
 let urls = [...]
 
 when(urls, maxPendingPromises: 4) { url in
    return downloadFile(url)
 }
 .then { files in
    // Now we have downloaded files.
 }

 */

public func when<U, V>(items: [U], maxPendingPromises: Int = 1, generator: (U) throws -> Promise<V>) -> Promise<[V]> {
    return Promise { fulfill, reject in
        var values = [V?](count: items.count, repeatedValue: nil)
        var pendingPromises = items.count

        let queue = PromiseQueue<V>(maxPendingPromises: maxPendingPromises)
        for i in 0..<items.count {
            queue.add {
                try generator(items[i])
            }
            .then { value -> Void in
                values[i] = value
                pendingPromises -= 1
            }
            .always {
                if pendingPromises == 0 {
                    fulfill(values.map { $0! })
                }
            }
            .error { error in
                reject(Error.When(i, error))
            }
        }
    }
}
