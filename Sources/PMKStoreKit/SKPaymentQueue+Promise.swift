#if canImport(StoreKit)

#if !PMKCocoaPods
import PromiseKit
#endif
import StoreKit

@available(watchOS 6.2, *)
public extension SKPaymentQueue {
    func restoreCompletedTransactions(_: PMKNamespacer) -> Promise<[SKPaymentTransaction]> {
        return PaymentObserver(self).promise
    }

    func restoreCompletedTransactions(_: PMKNamespacer, withApplicationUsername username: String?) -> Promise<[SKPaymentTransaction]> {
        return PaymentObserver(self, withApplicationUsername: true, userName: username).promise
    }
}

@available(watchOS 6.2, *)
private class PaymentObserver: NSObject, SKPaymentTransactionObserver {
    let (promise, seal) = Promise<[SKPaymentTransaction]>.pending()
    var retainCycle: PaymentObserver?
    var finishedTransactions = [SKPaymentTransaction]()

    //TODO:PMK7: this is weird, just have a `String?` parameter
    init(_ paymentQueue: SKPaymentQueue, withApplicationUsername: Bool = false, userName: String? = nil) {
        super.init()
        paymentQueue.add(self)
        withApplicationUsername ?
            paymentQueue.restoreCompletedTransactions() :
            paymentQueue.restoreCompletedTransactions(withApplicationUsername: userName)
        retainCycle = self
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions where transaction.transactionState == .restored {
            finishedTransactions.append(transaction)
            queue.finishTransaction(transaction)
        }
    }

    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        resolve(queue, nil)
    }

    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        resolve(queue, error)
    }

    func resolve(_ queue: SKPaymentQueue, _ error: Error?) {
        if let error = error {
            seal.reject(error)
        } else {
            seal.fulfill(finishedTransactions)
        }
        queue.remove(self)
        retainCycle = nil
    }
}

#endif
