//
//  PurchaseManager.swift
//  MonetixSDK
//
//  Created by MonetixSDK
//

import Foundation
import StoreKit

/// Manages StoreKit 2 purchases and transactions
internal class PurchaseManager {
    static let shared = PurchaseManager()

    private var observerMode: Bool = false
    private var transactionUpdateTask: Task<Void, Error>?
    private var logHandler: ((MonetixLogLevel, String, String) -> Void)?

    private init() {}

    func configure(observerMode: Bool) {
        self.observerMode = observerMode
    }

    func setLogHandler(_ handler: @escaping (MonetixLogLevel, String, String) -> Void) {
        self.logHandler = handler
    }

    private func log(_ level: MonetixLogLevel, _ message: String, function: String = #function) {
        logHandler?(level, message, function)
    }

    // MARK: - Transaction Observation

    /// Start listening for transaction updates
    func startObservingTransactions() {
        transactionUpdateTask = Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { return }

                do {
                    let transaction = try self.checkVerified(result)
                    await self.handleTransaction(transaction)
                } catch {
                    self.log(.error, "Transaction verification failed: \(error)")
                }
            }
        }
    }

    /// Stop listening for transaction updates
    func stopObservingTransactions() {
        transactionUpdateTask?.cancel()
        transactionUpdateTask = nil
    }

    // MARK: - Products

    /// Fetch products from App Store
    func fetchProducts(productIds: [String]) async throws -> [Product] {
        log(.info, "Fetching products: \(productIds)")

        do {
            let products = try await Product.products(for: productIds)
            log(.info, "Fetched \(products.count) products")
            return products
        } catch {
            log(.error, "Failed to fetch products: \(error)")
            throw MonetixError.storeKitError(error)
        }
    }

    // MARK: - Purchase

    /// Make a purchase
    func purchase(product: Product) async throws -> MonetixPurchaseResult {
        log(.info, "Starting purchase for: \(product.id)")

        guard !observerMode else {
            log(.warn, "Observer mode is enabled, purchase will not be processed")
            throw MonetixError.unknownError("Observer mode enabled")
        }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)

                log(.info, "Purchase successful: \(transaction.id)")

                // Finish the transaction
                await transaction.finish()

                // Get updated profile
                if let userId = Monetix.shared.currentUserId {
                    do {
                        let profile = try await APIService.shared.getProfile(userId: userId)
                        return MonetixPurchaseResult(profile: profile, transaction: transaction)
                    } catch {
                        log(.warn, "Failed to fetch profile after purchase: \(error)")
                        return MonetixPurchaseResult(profile: nil, transaction: transaction)
                    }
                }

                return MonetixPurchaseResult(profile: nil, transaction: transaction)

            case .userCancelled:
                log(.info, "Purchase cancelled by user")
                return MonetixPurchaseResult(profile: nil, isPurchaseCancelled: true)

            case .pending:
                log(.info, "Purchase pending approval")
                throw MonetixError.unknownError("Purchase pending approval")

            @unknown default:
                log(.error, "Unknown purchase result")
                throw MonetixError.unknownError("Unknown purchase result")
            }
        } catch {
            log(.error, "Purchase failed: \(error)")
            throw MonetixError.purchaseFailed(error)
        }
    }

    // MARK: - Restore

    /// Restore purchases
    func restorePurchases() async throws -> [Transaction] {
        log(.info, "Restoring purchases")

        var restoredTransactions: [Transaction] = []

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                restoredTransactions.append(transaction)
            } catch {
                log(.error, "Failed to verify transaction during restore: \(error)")
            }
        }

        log(.info, "Restored \(restoredTransactions.count) transactions")
        return restoredTransactions
    }

    /// Sync latest receipt with backend
    func syncReceipt(userId: String) async throws {
        log(.info, "Syncing receipt with backend")

        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              FileManager.default.fileExists(atPath: receiptURL.path) else {
            log(.warn, "No receipt found")
            return
        }

        do {
            let receiptData = try Data(contentsOf: receiptURL)
            let receiptString = receiptData.base64EncodedString()

            // Get the latest transaction
            for await result in Transaction.currentEntitlements {
                let transaction = try checkVerified(result)

                try await APIService.shared.syncReceipt(
                    userId: userId,
                    productId: transaction.productID,
                    transactionId: "\(transaction.id)",
                    originalTransactionId: "\(transaction.originalID)",
                    receiptData: receiptString
                )

                break // Only need the first active transaction
            }

        } catch {
            log(.error, "Failed to sync receipt: \(error)")
            throw error
        }
    }

    // MARK: - Transaction Handling

    private func handleTransaction(_ transaction: Transaction) async {
        log(.info, "Handling transaction: \(transaction.id)")

        // Finish the transaction
        await transaction.finish()

        // If not in observer mode, sync with backend
        if !observerMode, let userId = Monetix.shared.currentUserId {
            do {
                try await syncReceipt(userId: userId)
            } catch {
                log(.error, "Failed to sync transaction: \(error)")
            }
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw MonetixError.storeKitError(
                NSError(domain: "StoreKit", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Transaction verification failed"
                ])
            )
        }
    }
}
