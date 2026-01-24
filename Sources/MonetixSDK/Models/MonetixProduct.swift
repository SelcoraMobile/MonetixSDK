//
//  MonetixProduct.swift
//  MonetixSDK
//
//  Created by MonetixSDK
//

import Foundation
import StoreKit

// MARK: - Product (Adapty Compatible)

/// Represents a product (similar to AdaptyPaywallProduct)
public struct MonetixProduct: Codable, Sendable {
    /// Adapty product ID
    public let adaptyProductId: String

    /// Vendor product ID (App Store product ID)
    public let vendorProductId: String

    /// Product name
    public let localizedTitle: String

    /// Product description
    public let localizedDescription: String

    /// Product type
    public let productType: ProductType

    /// Price as Decimal
    public let price: Decimal

    /// Currency code (e.g., "USD", "EUR")
    public let currencyCode: String?

    /// Currency symbol (e.g., "$", "€")
    public let currencySymbol: String?

    /// Localized price string (e.g., "$9.99")
    public let localizedPrice: String?

    /// Region code
    public let regionCode: String?

    /// Whether the product is family shareable
    public let isFamilyShareable: Bool

    /// Subscription period (for subscriptions)
    public let subscriptionPeriod: MonetixSubscriptionPeriod?

    /// Localized subscription period (e.g., "1 month")
    public let localizedSubscriptionPeriod: String?

    /// Subscription group identifier
    public let subscriptionGroupIdentifier: String?

    /// Subscription offer (introductory/promotional)
    public let subscriptionOffer: MonetixSubscriptionOffer?

    /// Paywall product index
    public let paywallProductIndex: Int?

    /// Variation ID (for A/B testing)
    public let variationId: String?

    /// A/B test name
    public let paywallABTestName: String?

    /// Paywall name
    public let paywallName: String?

    public enum ProductType: String, Codable, Sendable {
        case subscription = "subscription"
        case consumable = "consumable"
        case nonConsumable = "non_consumable"
        case nonRenewingSubscription = "non_renewing_subscription"
    }

    enum CodingKeys: String, CodingKey {
        case adaptyProductId = "adapty_product_id"
        case vendorProductId = "vendor_product_id"
        case localizedTitle = "localized_title"
        case localizedDescription = "localized_description"
        case productType = "product_type"
        case price
        case currencyCode = "currency_code"
        case currencySymbol = "currency_symbol"
        case localizedPrice = "localized_price"
        case regionCode = "region_code"
        case isFamilyShareable = "is_family_shareable"
        case subscriptionPeriod = "subscription_period"
        case localizedSubscriptionPeriod = "localized_subscription_period"
        case subscriptionGroupIdentifier = "subscription_group_identifier"
        case subscriptionOffer = "subscription_offer"
        case paywallProductIndex = "paywall_product_index"
        case variationId = "variation_id"
        case paywallABTestName = "paywall_ab_test_name"
        case paywallName = "paywall_name"
    }

    // StoreKit Product association (internal, not encoded)
    internal var storeKitProduct: Product?

    /// Memberwise initializer for creating product directly
    public init(
        adaptyProductId: String,
        vendorProductId: String,
        localizedTitle: String,
        localizedDescription: String,
        productType: ProductType,
        price: Decimal,
        currencyCode: String?,
        localizedPrice: String?,
        isFamilyShareable: Bool,
        paywallProductIndex: Int?,
        variationId: String?,
        paywallAbTestName: String?,
        paywallName: String?,
        subscriptionPeriod: MonetixSubscriptionPeriod? = nil,
        currencySymbol: String? = nil,
        regionCode: String? = nil,
        localizedSubscriptionPeriod: String? = nil,
        subscriptionGroupIdentifier: String? = nil,
        subscriptionOffer: MonetixSubscriptionOffer? = nil
    ) {
        self.adaptyProductId = adaptyProductId
        self.vendorProductId = vendorProductId
        self.localizedTitle = localizedTitle
        self.localizedDescription = localizedDescription
        self.productType = productType
        self.price = price
        self.currencyCode = currencyCode
        self.currencySymbol = currencySymbol
        self.localizedPrice = localizedPrice
        self.regionCode = regionCode
        self.isFamilyShareable = isFamilyShareable
        self.subscriptionPeriod = subscriptionPeriod
        self.localizedSubscriptionPeriod = localizedSubscriptionPeriod
        self.subscriptionGroupIdentifier = subscriptionGroupIdentifier
        self.subscriptionOffer = subscriptionOffer
        self.paywallProductIndex = paywallProductIndex
        self.variationId = variationId
        self.paywallABTestName = paywallAbTestName
        self.paywallName = paywallName
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        adaptyProductId = try container.decodeIfPresent(String.self, forKey: .adaptyProductId) ?? ""
        vendorProductId = try container.decode(String.self, forKey: .vendorProductId)
        localizedTitle = try container.decodeIfPresent(String.self, forKey: .localizedTitle) ?? ""
        localizedDescription = try container.decodeIfPresent(String.self, forKey: .localizedDescription) ?? ""
        productType = try container.decodeIfPresent(ProductType.self, forKey: .productType) ?? .subscription
        price = try container.decodeIfPresent(Decimal.self, forKey: .price) ?? 0
        currencyCode = try container.decodeIfPresent(String.self, forKey: .currencyCode)
        currencySymbol = try container.decodeIfPresent(String.self, forKey: .currencySymbol)
        localizedPrice = try container.decodeIfPresent(String.self, forKey: .localizedPrice)
        regionCode = try container.decodeIfPresent(String.self, forKey: .regionCode)
        isFamilyShareable = try container.decodeIfPresent(Bool.self, forKey: .isFamilyShareable) ?? false
        subscriptionPeriod = try container.decodeIfPresent(MonetixSubscriptionPeriod.self, forKey: .subscriptionPeriod)
        localizedSubscriptionPeriod = try container.decodeIfPresent(String.self, forKey: .localizedSubscriptionPeriod)
        subscriptionGroupIdentifier = try container.decodeIfPresent(String.self, forKey: .subscriptionGroupIdentifier)
        subscriptionOffer = try container.decodeIfPresent(MonetixSubscriptionOffer.self, forKey: .subscriptionOffer)
        paywallProductIndex = try container.decodeIfPresent(Int.self, forKey: .paywallProductIndex)
        variationId = try container.decodeIfPresent(String.self, forKey: .variationId)
        paywallABTestName = try container.decodeIfPresent(String.self, forKey: .paywallABTestName)
        paywallName = try container.decodeIfPresent(String.self, forKey: .paywallName)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(adaptyProductId, forKey: .adaptyProductId)
        try container.encode(vendorProductId, forKey: .vendorProductId)
        try container.encode(localizedTitle, forKey: .localizedTitle)
        try container.encode(localizedDescription, forKey: .localizedDescription)
        try container.encode(productType, forKey: .productType)
        try container.encode(price, forKey: .price)
        try container.encodeIfPresent(currencyCode, forKey: .currencyCode)
        try container.encodeIfPresent(currencySymbol, forKey: .currencySymbol)
        try container.encodeIfPresent(localizedPrice, forKey: .localizedPrice)
        try container.encodeIfPresent(regionCode, forKey: .regionCode)
        try container.encode(isFamilyShareable, forKey: .isFamilyShareable)
        try container.encodeIfPresent(subscriptionPeriod, forKey: .subscriptionPeriod)
        try container.encodeIfPresent(localizedSubscriptionPeriod, forKey: .localizedSubscriptionPeriod)
        try container.encodeIfPresent(subscriptionGroupIdentifier, forKey: .subscriptionGroupIdentifier)
        try container.encodeIfPresent(subscriptionOffer, forKey: .subscriptionOffer)
        try container.encodeIfPresent(paywallProductIndex, forKey: .paywallProductIndex)
        try container.encodeIfPresent(variationId, forKey: .variationId)
        try container.encodeIfPresent(paywallABTestName, forKey: .paywallABTestName)
        try container.encodeIfPresent(paywallName, forKey: .paywallName)
    }

    /// Updates product with StoreKit product info
    internal mutating func updateWithStoreKitProduct(_ product: Product) {
        self.storeKitProduct = product
    }
}

// MARK: - Subscription Period (Adapty Compatible)

/// Represents a subscription period (similar to AdaptyProductSubscriptionPeriod)
public struct MonetixSubscriptionPeriod: Codable, Sendable {
    /// Period unit
    public let unit: Unit

    /// Number of units
    public let numberOfUnits: Int

    public enum Unit: String, Codable, Sendable {
        case day
        case week
        case month
        case year
        case unknown
    }

    enum CodingKeys: String, CodingKey {
        case unit
        case numberOfUnits = "number_of_units"
    }

    /// Create from StoreKit period
    @available(iOS 15.0, *)
    public init(from skPeriod: Product.SubscriptionPeriod) {
        self.numberOfUnits = skPeriod.value
        switch skPeriod.unit {
        case .day: self.unit = .day
        case .week: self.unit = .week
        case .month: self.unit = .month
        case .year: self.unit = .year
        @unknown default: self.unit = .unknown
        }
    }

    public init(unit: Unit, numberOfUnits: Int) {
        self.unit = unit
        self.numberOfUnits = numberOfUnits
    }
}

// MARK: - Subscription Offer (Adapty Compatible)

/// Represents a subscription offer (similar to AdaptySubscriptionOffer)
public struct MonetixSubscriptionOffer: Codable, Sendable {
    /// Offer identifier
    public let identifier: String?

    /// Offer type
    public let offerType: OfferType

    /// Subscription period for the offer
    public let subscriptionPeriod: MonetixSubscriptionPeriod?

    /// Number of periods
    public let numberOfPeriods: Int

    /// Payment mode
    public let paymentMode: PaymentMode

    /// Localized subscription period
    public let localizedSubscriptionPeriod: String?

    /// Localized number of periods
    public let localizedNumberOfPeriods: String?

    /// Price
    public let price: Decimal

    /// Currency code
    public let currencyCode: String?

    /// Localized price
    public let localizedPrice: String?

    public enum OfferType: String, Codable, Sendable {
        case introductory
        case promotional
        case code
        case unknown
    }

    public enum PaymentMode: String, Codable, Sendable {
        case payAsYouGo = "pay_as_you_go"
        case payUpFront = "pay_up_front"
        case freeTrial = "free_trial"
        case unknown
    }

    enum CodingKeys: String, CodingKey {
        case identifier
        case offerType = "offer_type"
        case subscriptionPeriod = "subscription_period"
        case numberOfPeriods = "number_of_periods"
        case paymentMode = "payment_mode"
        case localizedSubscriptionPeriod = "localized_subscription_period"
        case localizedNumberOfPeriods = "localized_number_of_periods"
        case price
        case currencyCode = "currency_code"
        case localizedPrice = "localized_price"
    }
}

// MARK: - Purchase Result (Adapty Compatible)

/// Purchase result (similar to AdaptyPurchaseResult)
public struct MonetixPurchaseResult: Sendable {
    /// Updated profile after purchase
    public let profile: MonetixProfile?

    /// StoreKit transaction
    public let transaction: Transaction?

    /// Whether the purchase was cancelled by user
    public let isPurchaseCancelled: Bool

    public init(profile: MonetixProfile?, transaction: Transaction? = nil, isPurchaseCancelled: Bool = false) {
        self.profile = profile
        self.transaction = transaction
        self.isPurchaseCancelled = isPurchaseCancelled
    }
}

// MARK: - Eligibility

/// Subscription offer eligibility
public enum MonetixEligibility: Sendable {
    case eligible
    case notEligible
    case unknown
}

// MARK: - Attribution Source

/// Attribution source for tracking
public enum MonetixAttributionSource: String, Sendable {
    case adjust
    case appsFlyer = "appsflyer"
    case branch
    case custom
    case appleSearchAds = "apple_search_ads"
}

/// Attribution data
public struct MonetixAttributionData: Sendable {
    public let source: MonetixAttributionSource
    public let attribution: [String: Any]
    public let networkUserId: String?

    public init(source: MonetixAttributionSource, attribution: [String: Any], networkUserId: String? = nil) {
        self.source = source
        self.attribution = attribution
        self.networkUserId = networkUserId
    }
}
