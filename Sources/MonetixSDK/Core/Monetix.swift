//
//  Monetix.swift
//  MonetixSDK
//
//  Created by MonetixSDK
//

import Foundation
import StoreKit
#if os(iOS)
import UIKit
#endif

/// Main Monetix SDK class (Adapty compatible API)
@available(iOS 15.0, *)
public class Monetix {
    /// Shared singleton instance
    public static let shared = Monetix()

    private var configuration: MonetixConfiguration?
    private var isActivated = false
    private var logHandler: ((MonetixLogLevel, String, String) -> Void)?
    private var fallbackPaywalls: MonetixFallbackPaywalls?
    private var profileId: String?

    /// Delegate for profile updates
    public weak var delegate: MonetixDelegate?

    internal var currentUserId: String? {
        return profileId ?? configuration?.userId
    }

    private init() {}

    // MARK: - Activation

    /// Activate Monetix SDK with configuration (Adapty compatible)
    public func activate(with configuration: MonetixConfiguration) async throws {
        guard !isActivated else {
            log(.warn, "Monetix is already activated")
            return
        }

        self.configuration = configuration

        // Configure services
        APIService.shared.configure(with: configuration)
        PurchaseManager.shared.configure(observerMode: configuration.observerMode)

        // Set log handlers
        if let logHandler = logHandler {
            APIService.shared.setLogHandler(logHandler)
            PurchaseManager.shared.setLogHandler(logHandler)
            await UserManager.shared.setLogHandler(logHandler)
            await AnalyticsService.shared.setLogHandler(logHandler)
        }

        // Start observing transactions
        if !configuration.observerMode {
            PurchaseManager.shared.startObservingTransactions()
        }

        // Generate or use provided user ID
        if let userId = configuration.userId {
            self.profileId = userId
            // Sync user with backend including device attributes
            do {
                let deviceAttributes = collectDeviceAttributes()
                _ = try await APIService.shared.syncUser(userId: userId, attributes: deviceAttributes)
            } catch {
                log(.warn, "Failed to sync user: \(error)")
            }
        } else {
            // Generate anonymous user ID
            self.profileId = UUID().uuidString
        }

        isActivated = true
        log(.info, "Monetix SDK activated successfully")
    }

    /// Static activation method (Adapty style)
    public static func activate(with configuration: MonetixConfiguration) async throws {
        try await shared.activate(with: configuration)
    }

    /// Set log handler for SDK logs
    public func setLogHandler(_ handler: @escaping (MonetixLogLevel, String, String) -> Void) {
        self.logHandler = handler

        // Update all services
        APIService.shared.setLogHandler(handler)
        PurchaseManager.shared.setLogHandler(handler)
        Task {
            await UserManager.shared.setLogHandler(handler)
            await AnalyticsService.shared.setLogHandler(handler)
        }
    }

    /// Static log handler setter
    public static func setLogHandler(_ handler: @escaping (MonetixLogLevel, String, String) -> Void) {
        shared.setLogHandler(handler)
    }

    /// Collects device attributes for user sync (country, language, timezone, device info)
    private func collectDeviceAttributes() -> [String: Any] {
        var attributes: [String: Any] = [:]

        // Country/Region from device locale
        if #available(macOS 13, iOS 16, *) {
            if let regionCode = Locale.current.region?.identifier {
                attributes["country"] = regionCode
            }
        } else {
            if let regionCode = Locale.current.regionCode {
                attributes["country"] = regionCode
            }
        }

        // Language
        if #available(macOS 13, iOS 16, *) {
            if let languageCode = Locale.current.language.languageCode?.identifier {
                attributes["language"] = languageCode
            }
        } else {
            if let languageCode = Locale.current.languageCode {
                attributes["language"] = languageCode
            }
        }

        // Timezone
        attributes["timezone"] = TimeZone.current.identifier

        // Device info
        #if os(iOS)
        attributes["device_model"] = UIDevice.current.model
        attributes["os_version"] = UIDevice.current.systemVersion
        attributes["os_name"] = UIDevice.current.systemName
        #endif

        // App version
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            attributes["app_version"] = appVersion
        }

        // Build number
        if let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            attributes["build_number"] = buildNumber
        }

        return attributes
    }

    private func log(_ level: MonetixLogLevel, _ message: String, function: String = #function) {
        logHandler?(level, message, function)
    }

    private func ensureActivated() throws {
        guard isActivated else {
            throw MonetixError.notActivated
        }
    }

    // MARK: - User Identification

    /// Identify user with custom user ID (Adapty compatible)
    public func identify(_ customerUserId: String) async throws {
        try ensureActivated()

        guard let currentId = currentUserId else {
            throw MonetixError.userNotFound
        }

        log(.info, "Identifying user: \(customerUserId)")

        let profile = try await APIService.shared.identify(userId: currentId, customerUserId: customerUserId)
        self.profileId = customerUserId

        // Notify delegate
        delegate?.didReceiveProfile(profile)
    }

    /// Static identify method
    public static func identify(_ customerUserId: String) async throws {
        try await shared.identify(customerUserId)
    }

    /// Identify with completion handler (Adapty compatible)
    public func identify(_ customerUserId: String, completion: @escaping (Result<Void, MonetixError>) -> Void) {
        Task {
            do {
                try await identify(customerUserId)
                completion(.success(()))
            } catch let error as MonetixError {
                completion(.failure(error))
            } catch {
                completion(.failure(.unknownError(error.localizedDescription)))
            }
        }
    }

    /// Logout user and reset to anonymous (Adapty compatible)
    public func logout() async throws {
        try ensureActivated()

        guard let userId = currentUserId else {
            throw MonetixError.userNotFound
        }

        log(.info, "Logging out user")

        try await APIService.shared.logout(userId: userId)

        // Reset to anonymous user
        self.profileId = UUID().uuidString
        await UserManager.shared.clearCache()
    }

    /// Static logout method
    public static func logout() async throws {
        try await shared.logout()
    }

    /// Logout with completion handler
    public func logout(completion: @escaping (Result<Void, MonetixError>) -> Void) {
        Task {
            do {
                try await logout()
                completion(.success(()))
            } catch let error as MonetixError {
                completion(.failure(error))
            } catch {
                completion(.failure(.unknownError(error.localizedDescription)))
            }
        }
    }

    // MARK: - User Profile

    /// Get user profile (async/await - Adapty compatible)
    public func getProfile() async throws -> MonetixProfile {
        try ensureActivated()

        guard let userId = currentUserId else {
            throw MonetixError.userNotFound
        }

        let profile = try await UserManager.shared.getProfile(userId: userId)
        delegate?.didReceiveProfile(profile)
        return profile
    }

    /// Static getProfile method
    public static func getProfile() async throws -> MonetixProfile {
        return try await shared.getProfile()
    }

    /// Get user profile (completion handler style - Adapty compatible)
    public func getProfile(completion: @escaping (Result<MonetixProfile, MonetixError>) -> Void) {
        Task {
            do {
                let profile = try await getProfile()
                completion(.success(profile))
            } catch let error as MonetixError {
                completion(.failure(error))
            } catch {
                completion(.failure(.unknownError(error.localizedDescription)))
            }
        }
    }

    /// Update profile with parameters (Adapty compatible)
    public func updateProfile(params: MonetixProfileParameters) async throws -> MonetixProfile {
        try ensureActivated()

        guard let userId = currentUserId else {
            throw MonetixError.userNotFound
        }

        log(.info, "Updating profile")

        let profile = try await APIService.shared.updateProfile(userId: userId, params: params)
        await UserManager.shared.updateCache(profile: profile)
        delegate?.didReceiveProfile(profile)
        return profile
    }

    /// Static updateProfile method
    public static func updateProfile(params: MonetixProfileParameters) async throws -> MonetixProfile {
        return try await shared.updateProfile(params: params)
    }

    /// Update profile with completion handler
    public func updateProfile(params: MonetixProfileParameters, completion: @escaping (Result<MonetixProfile, MonetixError>) -> Void) {
        Task {
            do {
                let profile = try await updateProfile(params: params)
                completion(.success(profile))
            } catch let error as MonetixError {
                completion(.failure(error))
            } catch {
                completion(.failure(.unknownError(error.localizedDescription)))
            }
        }
    }

    /// Check premium access
    public func checkAccess() async throws -> Bool {
        try ensureActivated()

        guard let userId = currentUserId else {
            throw MonetixError.userNotFound
        }

        let response = try await APIService.shared.checkAccess(userId: userId)
        return response.hasPremium
    }

    /// Static checkAccess method
    public static func checkAccess() async throws -> Bool {
        return try await shared.checkAccess()
    }

    // MARK: - Paywalls

    /// Get paywall by placement ID (async/await - Adapty compatible)
    public func getPaywall(placementId: String, locale: String? = nil) async throws -> MonetixPaywall {
        try ensureActivated()

        guard let userId = currentUserId else {
            throw MonetixError.userNotFound
        }

        let localeString = locale ?? Locale.current.languageCode ?? "en"

        do {
            return try await APIService.shared.getPaywall(placementId: placementId, userId: userId, locale: localeString)
        } catch {
            // Try fallback paywalls if available
            if let fallback = fallbackPaywalls?.paywall(forPlacement: placementId) {
                log(.info, "Using fallback paywall for placement: \(placementId)")
                return fallback
            }
            throw error
        }
    }

    /// Static getPaywall method
    public static func getPaywall(placementId: String, locale: String? = nil) async throws -> MonetixPaywall {
        return try await shared.getPaywall(placementId: placementId, locale: locale)
    }

    /// Get paywall by placement ID (completion handler style - Adapty compatible)
    public func getPaywall(
        placementId: String,
        locale: String? = nil,
        completion: @escaping (Result<MonetixPaywall, MonetixError>) -> Void
    ) {
        Task {
            do {
                let paywall = try await getPaywall(placementId: placementId, locale: locale)
                completion(.success(paywall))
            } catch let error as MonetixError {
                completion(.failure(error))
            } catch {
                completion(.failure(.unknownError(error.localizedDescription)))
            }
        }
    }

    /// Get products for paywall (async/await - Adapty compatible)
    public func getPaywallProducts(paywall: MonetixPaywall) async throws -> [MonetixProduct] {
        try ensureActivated()

        // Fetch StoreKit products
        let productIds = paywall.vendorProductIds
        guard !productIds.isEmpty else {
            return []
        }

        let storeKitProducts = try await PurchaseManager.shared.fetchProducts(productIds: productIds)

        // Create MonetixProduct array with StoreKit data
        var products: [MonetixProduct] = []

        for (index, productId) in productIds.enumerated() {
            if let skProduct = storeKitProducts.first(where: { $0.id == productId }) {
                let product = createProduct(from: skProduct, paywall: paywall, index: index)
                products.append(product)
            }
        }

        return products
    }

    /// Static getPaywallProducts method
    public static func getPaywallProducts(paywall: MonetixPaywall) async throws -> [MonetixProduct] {
        return try await shared.getPaywallProducts(paywall: paywall)
    }

    /// Get products for paywall (completion handler style - Adapty compatible)
    public func getPaywallProducts(
        paywall: MonetixPaywall,
        completion: @escaping (Result<[MonetixProduct], MonetixError>) -> Void
    ) {
        Task {
            do {
                let products = try await getPaywallProducts(paywall: paywall)
                completion(.success(products))
            } catch let error as MonetixError {
                completion(.failure(error))
            } catch {
                completion(.failure(.unknownError(error.localizedDescription)))
            }
        }
    }

    private func createProduct(from skProduct: Product, paywall: MonetixPaywall, index: Int) -> MonetixProduct {
        let subscriptionPeriod: MonetixSubscriptionPeriod?
        if let period = skProduct.subscription?.subscriptionPeriod {
            subscriptionPeriod = MonetixSubscriptionPeriod(from: period)
        } else {
            subscriptionPeriod = nil
        }

        let productType: MonetixProduct.ProductType
        switch skProduct.type {
        case .autoRenewable:
            productType = .subscription
        case .consumable:
            productType = .consumable
        case .nonConsumable:
            productType = .nonConsumable
        case .nonRenewable:
            productType = .nonRenewingSubscription
        default:
            productType = .subscription
        }

        // Create product directly without JSON serialization for safety
        var product = MonetixProduct(
            id: skProduct.id,
            adaptyProductId: skProduct.id,
            vendorProductId: skProduct.id,
            localizedTitle: skProduct.displayName,
            localizedDescription: skProduct.description,
            productType: productType,
            price: skProduct.price,
            currencyCode: skProduct.priceFormatStyle.currencyCode,
            localizedPrice: skProduct.displayPrice,
            isFamilyShareable: skProduct.isFamilyShareable,
            paywallProductIndex: index,
            variationId: paywall.variationId,
            paywallAbTestName: paywall.abTestName,
            paywallName: paywall.name,
            subscriptionPeriod: subscriptionPeriod
        )
        product.storeKitProduct = skProduct
        return product
    }

    // MARK: - Fallback Paywalls

    /// Set fallback paywalls from file URL (Adapty compatible)
    public func setFallbackPaywalls(fileURL: URL) throws {
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        fallbackPaywalls = try decoder.decode(MonetixFallbackPaywalls.self, from: data)
        log(.info, "Loaded fallback paywalls from file")
    }

    /// Static setFallbackPaywalls method
    public static func setFallbackPaywalls(fileURL: URL) throws {
        try shared.setFallbackPaywalls(fileURL: fileURL)
    }

    /// Set fallback paywalls from data
    public func setFallbackPaywalls(data: Data) throws {
        let decoder = JSONDecoder()
        fallbackPaywalls = try decoder.decode(MonetixFallbackPaywalls.self, from: data)
        log(.info, "Loaded fallback paywalls from data")
    }

    // MARK: - Purchases

    /// Make a purchase (async/await - Adapty compatible)
    public func makePurchase(product: MonetixProduct) async throws -> MonetixPurchaseResult {
        try ensureActivated()

        guard let storeKitProduct = product.storeKitProduct else {
            throw MonetixError.productNotFound
        }

        guard let userId = currentUserId else {
            throw MonetixError.userNotFound
        }

        // Track purchase started
        await AnalyticsService.shared.trackEvent(userId: userId, eventType: .purchaseStarted, properties: [
            "product_id": product.vendorProductId,
            "paywall_name": product.paywallName ?? "",
            "variation_id": product.variationId ?? ""
        ])

        let result = try await PurchaseManager.shared.purchase(product: storeKitProduct)

        if !result.isPurchaseCancelled, let transaction = result.transaction {
            // Report purchase to backend
            let profile = try await APIService.shared.reportPurchase(
                userId: userId,
                productId: product.vendorProductId,
                transactionId: "\(transaction.id)",
                originalTransactionId: "\(transaction.originalID)",
                price: storeKitProduct.price,
                currency: storeKitProduct.priceFormatStyle.currencyCode,
                variationId: product.variationId,
                paywallName: product.paywallName
            )

            await UserManager.shared.updateCache(profile: profile)
            delegate?.didReceiveProfile(profile)

            return MonetixPurchaseResult(profile: profile, transaction: transaction)
        }

        return result
    }

    /// Static makePurchase method
    public static func makePurchase(product: MonetixProduct) async throws -> MonetixPurchaseResult {
        return try await shared.makePurchase(product: product)
    }

    /// Make a purchase (completion handler style - Adapty compatible)
    public func makePurchase(
        product: MonetixProduct,
        completion: @escaping (Result<MonetixPurchaseResult, MonetixError>) -> Void
    ) {
        Task {
            do {
                let result = try await makePurchase(product: product)
                completion(.success(result))
            } catch let error as MonetixError {
                completion(.failure(error))
            } catch {
                completion(.failure(.unknownError(error.localizedDescription)))
            }
        }
    }

    /// Restore purchases (async/await - Adapty compatible)
    public func restorePurchases() async throws -> MonetixProfile {
        try ensureActivated()

        guard let userId = currentUserId else {
            throw MonetixError.userNotFound
        }

        // Track restore started
        await AnalyticsService.shared.trackEvent(userId: userId, eventType: .restoreStarted)

        let transactions = try await PurchaseManager.shared.restorePurchases()

        // Build transactions array for backend
        let transactionsData: [[String: Any]] = transactions.map { transaction in
            [
                "transaction_id": "\(transaction.id)",
                "original_transaction_id": "\(transaction.originalID)",
                "product_id": transaction.productID
            ]
        }

        // Report to backend
        let profile = try await APIService.shared.restorePurchases(userId: userId, transactions: transactionsData)

        await UserManager.shared.updateCache(profile: profile)
        delegate?.didReceiveProfile(profile)

        return profile
    }

    /// Static restorePurchases method
    public static func restorePurchases() async throws -> MonetixProfile {
        return try await shared.restorePurchases()
    }

    /// Restore purchases (completion handler style - Adapty compatible)
    public func restorePurchases(completion: @escaping (Result<MonetixProfile, MonetixError>) -> Void) {
        Task {
            do {
                let profile = try await restorePurchases()
                completion(.success(profile))
            } catch let error as MonetixError {
                completion(.failure(error))
            } catch {
                completion(.failure(.unknownError(error.localizedDescription)))
            }
        }
    }

    // MARK: - A/B Testing

    /// Set variation ID for a transaction (Adapty compatible)
    public func setVariationId(_ variationId: String, forTransactionId transactionId: String) async throws {
        try ensureActivated()

        guard let userId = currentUserId else {
            throw MonetixError.userNotFound
        }

        try await APIService.shared.setVariationId(variationId: variationId, transactionId: transactionId, userId: userId)
    }

    /// Static setVariationId method
    public static func setVariationId(_ variationId: String, forTransactionId transactionId: String) async throws {
        try await shared.setVariationId(variationId, forTransactionId: transactionId)
    }

    // MARK: - Promo Codes

    /// Present code redemption sheet (Adapty compatible)
    #if os(iOS)
    public func presentCodeRedemptionSheet() {
        SKPaymentQueue.default().presentCodeRedemptionSheet()
    }

    /// Static presentCodeRedemptionSheet method
    public static func presentCodeRedemptionSheet() {
        shared.presentCodeRedemptionSheet()
    }
    #endif

    // MARK: - Attribution

    /// Update attribution data (Adapty compatible)
    public func updateAttribution(_ attribution: [String: Any], source: MonetixAttributionSource, networkUserId: String? = nil) async throws {
        try ensureActivated()

        guard let userId = currentUserId else {
            throw MonetixError.userNotFound
        }

        let attributionData = MonetixAttributionData(source: source, attribution: attribution, networkUserId: networkUserId)
        try await APIService.shared.updateAttribution(userId: userId, attribution: attributionData)
    }

    /// Static updateAttribution method
    public static func updateAttribution(_ attribution: [String: Any], source: MonetixAttributionSource, networkUserId: String? = nil) async throws {
        try await shared.updateAttribution(attribution, source: source, networkUserId: networkUserId)
    }

    // MARK: - Analytics

    /// Log paywall show event (Adapty compatible)
    public func logShowPaywall(_ paywall: MonetixPaywall) {
        guard let userId = currentUserId else {
            log(.warn, "Cannot log paywall show: no user ID available")
            return
        }

        Task {
            await AnalyticsService.shared.trackPaywallOpen(
                userId: userId,
                paywallName: paywall.name,
                isABTest: paywall.abTestName != nil,
                abTestName: paywall.abTestName
            )
        }
    }

    /// Static logShowPaywall method
    public static func logShowPaywall(_ paywall: MonetixPaywall) {
        shared.logShowPaywall(paywall)
    }

    /// Log onboarding screen show (Adapty compatible)
    public func logShowOnboarding(name: String?, screenName: String?, screenOrder: Int) {
        guard let userId = currentUserId else {
            log(.warn, "Cannot log onboarding show: no user ID available")
            return
        }

        Task {
            await AnalyticsService.shared.trackEvent(
                userId: userId,
                eventType: .paywallOpen,
                properties: [
                    "onboarding_name": name ?? "",
                    "screen_name": screenName ?? "",
                    "screen_order": screenOrder,
                    "type": "onboarding"
                ]
            )
        }
    }

    /// Static logShowOnboarding method
    public static func logShowOnboarding(name: String?, screenName: String?, screenOrder: Int) {
        shared.logShowOnboarding(name: name, screenName: screenName, screenOrder: screenOrder)
    }

    /// Track custom event
    public func trackEvent(
        eventType: MonetixEventType,
        properties: [String: Any] = [:]
    ) {
        guard let userId = currentUserId else {
            log(.warn, "Cannot track event: no user ID available")
            return
        }
        Task {
            await AnalyticsService.shared.trackEvent(userId: userId, eventType: eventType, properties: properties)
        }
    }

    // MARK: - Cleanup

    deinit {
        PurchaseManager.shared.stopObservingTransactions()
    }
}

// MARK: - Delegate Protocol

/// Delegate for receiving profile updates (Adapty compatible)
@available(iOS 15.0, *)
public protocol MonetixDelegate: AnyObject {
    /// Called when profile is updated
    func didReceiveProfile(_ profile: MonetixProfile)
}

// MARK: - Default Delegate Implementation

@available(iOS 15.0, *)
public extension MonetixDelegate {
    func didReceiveProfile(_ profile: MonetixProfile) {}
}
