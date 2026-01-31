//
//  MonetixSDK.swift
//  MonetixSDK
//
//  Copyright © 2024 SelcoraMobile. All rights reserved.
//

import Foundation

/// MonetixSDK - iOS Subscription Management System
///
/// A professional subscription and monetization infrastructure for iOS apps.
/// Integrates with Apple's StoreKit 2 system to help manage, optimize, and analyze subscription sales.
///
/// ## Usage Example:
/// ```swift
/// import MonetixSDK
///
/// // 1. Configure SDK
/// let configuration = MonetixConfiguration
///     .builder(withAPIKey: "your-api-key")
///     .with(customerUserId: "user-123")
///     .with(environment: .production)
///     .with(observerMode: false)
///     .build()
///
/// // 2. Activate SDK
/// try await Monetix.shared.activate(with: configuration)
///
/// // 3. Set log handler (optional)
/// Monetix.shared.setLogHandler { level, message, function in
///     print("[\(level)] \(message)")
/// }
///
/// // 4. Get user profile
/// Monetix.shared.getProfile { result in
///     switch result {
///     case .success(let profile):
///         print("isPremium: \(profile.isPremium)")
///     case .failure(let error):
///         print("Error: \(error)")
///     }
/// }
///
/// // 5. Get paywall
/// Monetix.shared.getPaywall(placementId: "onboarding") { result in
///     switch result {
///     case .success(let paywall):
///         print("Paywall: \(paywall.name)")
///     case .failure(let error):
///         print("Error: \(error)")
///     }
/// }
/// ```
///
public struct MonetixSDK {
    /// Current SDK version
    public static let version = "1.0.0"
}
