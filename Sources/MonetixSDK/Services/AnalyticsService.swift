//
//  AnalyticsService.swift
//  MonetixSDK
//
//  Created by MonetixSDK
//

import Foundation

// Note: MonetixEventType is defined in MonetixDelegate.swift

/// Service for tracking analytics events
internal actor AnalyticsService {
    static let shared = AnalyticsService()

    private var logHandler: ((MonetixLogLevel, String, String) -> Void)?
    private var eventQueue: [PendingEvent] = []
    private var isProcessingQueue = false

    private struct PendingEvent {
        let userId: String
        let eventType: String
        let properties: [String: Any]
        let timestamp: Date
    }

    private init() {}

    func setLogHandler(_ handler: @escaping (MonetixLogLevel, String, String) -> Void) {
        self.logHandler = handler
    }

    private func log(_ level: MonetixLogLevel, _ message: String, function: String = #function) {
        logHandler?(level, message, function)
    }

    // MARK: - Event Tracking

    /// Track an event
    func trackEvent(
        userId: String,
        eventType: MonetixEventType,
        properties: [String: Any] = [:]
    ) {
        var enrichedProperties = properties
        enrichedProperties["sdk_version"] = "1.0.0" // TODO: Make dynamic
        enrichedProperties["platform"] = "ios"

        log(.debug, "Tracking event: \(eventType.rawValue)")

        let event = PendingEvent(
            userId: userId,
            eventType: eventType.rawValue,
            properties: enrichedProperties,
            timestamp: Date()
        )

        eventQueue.append(event)

        Task {
            await processQueue()
        }
    }

    /// Track paywall open
    func trackPaywallOpen(
        userId: String,
        paywallName: String,
        isABTest: Bool,
        abTestName: String?
    ) {
        trackEvent(userId: userId, eventType: .paywallOpen, properties: [
            "paywall_name": paywallName,
            "is_ab_test": isABTest,
            "ab_test_name": abTestName ?? ""
        ])
    }

    /// Track paywall close
    func trackPaywallClose(userId: String) {
        trackEvent(userId: userId, eventType: .paywallClose)
    }

    /// Track purchase success
    func trackPurchaseSuccess(
        userId: String,
        transactionId: String,
        paywallName: String,
        productId: String,
        isABTest: Bool,
        abTestName: String?
    ) {
        trackEvent(userId: userId, eventType: .purchaseSuccess, properties: [
            "transaction_id": transactionId,
            "paywall_name": paywallName,
            "product_id": productId,
            "is_ab_test": isABTest,
            "ab_test_name": abTestName ?? ""
        ])
    }

    /// Track purchase failure
    func trackPurchaseFailed(
        userId: String,
        paywallName: String,
        productId: String,
        errorCode: String,
        errorDetail: String,
        isABTest: Bool,
        abTestName: String?
    ) {
        trackEvent(userId: userId, eventType: .purchaseFailed, properties: [
            "paywall_name": paywallName,
            "product_id": productId,
            "error_code": errorCode,
            "error_detail": errorDetail,
            "is_ab_test": isABTest,
            "ab_test_name": abTestName ?? ""
        ])
    }

    /// Track restore success
    func trackRestoreSuccess(userId: String) {
        trackEvent(userId: userId, eventType: .restoreSuccess)
    }

    /// Track restore failure
    func trackRestoreFailed(userId: String, error: String) {
        trackEvent(userId: userId, eventType: .restoreFailed, properties: [
            "error": error
        ])
    }

    /// Track paywall error
    func trackPaywallError(
        userId: String,
        paywallName: String,
        errorDetail: String
    ) {
        trackEvent(userId: userId, eventType: .paywallError, properties: [
            "paywall_name": paywallName,
            "error_detail": errorDetail
        ])
    }

    // MARK: - Queue Processing

    private func processQueue() async {
        guard !isProcessingQueue, !eventQueue.isEmpty else { return }

        isProcessingQueue = true

        while !eventQueue.isEmpty {
            let event = eventQueue.removeFirst()

            do {
                try await APIService.shared.trackEvent(
                    userId: event.userId,
                    eventName: event.eventType,
                    metadata: event.properties
                )
                log(.debug, "Event sent: \(event.eventType)")
            } catch {
                log(.error, "Failed to send event: \(error)")
                // Re-queue the event (at the end)
                eventQueue.append(event)
                isProcessingQueue = false
                return
            }
        }

        isProcessingQueue = false
    }

    /// Flush all pending events
    func flush() async {
        while !eventQueue.isEmpty {
            await Task.yield() // Give time for queue to process
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
    }
}
