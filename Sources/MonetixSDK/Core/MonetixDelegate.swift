//
//  MonetixDelegate.swift
//  MonetixSDK
//
//  Created by MonetixSDK
//

import Foundation

#if canImport(UIKit)
import UIKit

/// Delegate protocol for paywall controller events (similar to AdaptyPaywallControllerDelegate)
/// Works with both MonetixPaywallController (custom UI) and MonetixBuilderController (server-driven UI)
@available(iOS 15.0, *)
public protocol MonetixPaywallControllerDelegate: AnyObject {
    /// Called when paywall is about to be presented
    func paywallControllerDidStartPresenting(_ controller: Any)

    /// Called when paywall was dismissed
    func paywallControllerDidDismiss(_ controller: Any)

    /// Called when purchase was successful
    func paywallController(
        _ controller: Any,
        didFinishPurchase product: MonetixProduct,
        purchaseResult: MonetixPurchaseResult
    )

    /// Called when purchase failed
    func paywallController(
        _ controller: Any,
        didFailPurchase product: MonetixProduct,
        error: MonetixError
    )

    /// Called when purchase was cancelled by user
    func paywallController(
        _ controller: Any,
        didCancelPurchase product: MonetixProduct
    )

    /// Called when restore was successful
    func paywallController(
        _ controller: Any,
        didFinishRestoreWith profile: MonetixProfile
    )

    /// Called when restore failed
    func paywallController(
        _ controller: Any,
        didFailRestoreWith error: MonetixError
    )

    /// Called when paywall failed to render
    func paywallController(
        _ controller: Any,
        didFailRenderingWith error: MonetixError
    )

    /// Called when custom action is triggered (from remote config or builder)
    func paywallController(
        _ controller: Any,
        didPerformAction action: String
    )

    /// Called when product is selected in paywall builder
    func paywallController(
        _ controller: Any,
        didSelectProduct product: MonetixProduct
    )
}

/// Default implementations for optional delegate methods
@available(iOS 15.0, *)
public extension MonetixPaywallControllerDelegate {
    func paywallControllerDidStartPresenting(_ controller: Any) {}
    func paywallControllerDidDismiss(_ controller: Any) {}
    func paywallController(_ controller: Any, didCancelPurchase product: MonetixProduct) {}
    func paywallController(_ controller: Any, didFailRenderingWith error: MonetixError) {}
    func paywallController(_ controller: Any, didPerformAction action: String) {}
    func paywallController(_ controller: Any, didSelectProduct product: MonetixProduct) {}
}
#endif

/// Analytics delegate protocol (for custom analytics integration)
public protocol MonetixAnalyticsDelegate: AnyObject {
    /// Called when paywall opens
    func onPaywallOpen(paywallName: String, isABTest: Bool, abTestName: String?)

    /// Called when paywall closes
    func onPaywallClose()

    /// Called when purchase succeeds
    func onPurchaseSuccess(
        purchaseTransactionId: String,
        paywallName: String,
        productId: String,
        isABTest: Bool,
        abTestName: String?
    )

    /// Called when purchase fails
    func onPurchaseFailed(
        paywallName: String,
        isABTest: Bool,
        abTestName: String?,
        productCode: String,
        errorCode: String,
        errorDetail: String
    )

    /// Called when restore succeeds
    func onRestoreSuccess()

    /// Called when paywall is not visible (error)
    func isNotVisiblePaywall(errorDetail: String, paywallName: String)
}

/// Default implementations for optional analytics delegate methods
public extension MonetixAnalyticsDelegate {
    func onPaywallClose() {}
    func isNotVisiblePaywall(errorDetail: String, paywallName: String) {}
}

/// Event types for analytics tracking (Adapty compatible)
public enum MonetixEventType: String, Sendable {
    case paywallOpen = "paywall_open"
    case paywallClose = "paywall_close"
    case productViewed = "product_viewed"
    case purchaseStarted = "purchase_started"
    case purchaseSuccess = "purchase_success"
    case purchaseFailed = "purchase_failed"
    case purchaseCancelled = "purchase_cancelled"
    case restoreStarted = "restore_started"
    case restoreSuccess = "restore_success"
    case restoreFailed = "restore_failed"
    case subscriptionRenewed = "subscription_renewed"
    case subscriptionExpired = "subscription_expired"
    case subscriptionCancelled = "subscription_cancelled"
    case trialStarted = "trial_started"
    case trialConverted = "trial_converted"
    case trialExpired = "trial_expired"
    case onboardingStarted = "onboarding_started"
    case onboardingCompleted = "onboarding_completed"
    case paywallError = "paywall_error"
    case customEvent = "custom"
}
