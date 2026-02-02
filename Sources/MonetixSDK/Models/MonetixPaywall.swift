//
//  MonetixPaywall.swift
//  MonetixSDK
//
//  Created by MonetixSDK
//

import Foundation

// MARK: - Paywall (Adapty Compatible)

/// Represents a paywall (similar to AdaptyPaywall)
public struct MonetixPaywall: Codable, Sendable {
    /// Paywall ID
    public let id: String

    /// Placement ID where this paywall is shown
    public let placementId: String

    /// Instance identity for analytics
    public let instanceIdentity: String

    /// Variation ID for A/B testing
    public let variationId: String?

    /// Paywall name
    public let name: String

    /// A/B test name
    public let abTestName: String?

    /// Revision number
    public let revision: Int

    /// Locale for the paywall
    public let locale: String

    /// Remote config data (for custom UI implementation)
    public let remoteConfig: MonetixRemoteConfig?

    /// Whether this paywall has a view configuration (for Paywall Builder)
    public let hasViewConfiguration: Bool

    /// View configuration for Paywall Builder (server-driven UI)
    /// When this is present and hasViewConfiguration is true, use MonetixBuilderController to render
    public let viewConfiguration: MonetixViewConfiguration?

    /// Vendor product IDs in this paywall
    public let vendorProductIds: [String]

    /// Products (populated after fetching from StoreKit)
    public var products: [MonetixProduct]

    enum CodingKeys: String, CodingKey {
        case id
        case placementId = "placement_id"
        case instanceIdentity = "instance_identity"
        case variationId = "variation_id"
        case name
        case abTestName = "ab_test_name"
        case revision
        case locale
        case remoteConfig = "remote_config"
        case hasViewConfiguration = "has_view_configuration"
        case viewConfiguration = "view_configuration"
        case vendorProductIds = "vendor_product_ids"
        case products
    }

    /// Memberwise initializer
    public init(
        id: String,
        placementId: String,
        instanceIdentity: String,
        variationId: String?,
        name: String,
        abTestName: String?,
        revision: Int,
        locale: String,
        hasViewConfiguration: Bool,
        vendorProductIds: [String],
        products: [MonetixProduct],
        remoteConfig: MonetixRemoteConfig? = nil,
        viewConfiguration: MonetixViewConfiguration? = nil
    ) {
        self.id = id
        self.placementId = placementId
        self.instanceIdentity = instanceIdentity
        self.variationId = variationId
        self.name = name
        self.abTestName = abTestName
        self.revision = revision
        self.locale = locale
        self.remoteConfig = remoteConfig
        self.hasViewConfiguration = hasViewConfiguration
        self.viewConfiguration = viewConfiguration
        self.vendorProductIds = vendorProductIds
        self.products = products
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        placementId = try container.decodeIfPresent(String.self, forKey: .placementId) ?? ""
        instanceIdentity = try container.decodeIfPresent(String.self, forKey: .instanceIdentity) ?? UUID().uuidString
        variationId = try container.decodeIfPresent(String.self, forKey: .variationId)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        abTestName = try container.decodeIfPresent(String.self, forKey: .abTestName)
        revision = try container.decodeIfPresent(Int.self, forKey: .revision) ?? 1
        locale = try container.decodeIfPresent(String.self, forKey: .locale) ?? "en"
        remoteConfig = try container.decodeIfPresent(MonetixRemoteConfig.self, forKey: .remoteConfig)
        hasViewConfiguration = try container.decodeIfPresent(Bool.self, forKey: .hasViewConfiguration) ?? false
        viewConfiguration = try container.decodeIfPresent(MonetixViewConfiguration.self, forKey: .viewConfiguration)
        vendorProductIds = try container.decodeIfPresent([String].self, forKey: .vendorProductIds) ?? []
        products = try container.decodeIfPresent([MonetixProduct].self, forKey: .products) ?? []
    }

    /// Check if paywall has remote config for custom UI
    public var hasRemoteConfig: Bool {
        return remoteConfig != nil
    }

    /// Check if this paywall uses Paywall Builder (server-driven UI)
    /// When true, use MonetixBuilderController or MonetixBuilderView to render
    public var usesPaywallBuilder: Bool {
        return hasViewConfiguration && viewConfiguration != nil
    }
}

// MARK: - Remote Config (Adapty Compatible)

/// Remote configuration for paywall (similar to AdaptyRemoteConfig)
public struct MonetixRemoteConfig: Codable, Sendable {
    /// Locale for the config
    public let locale: String

    /// JSON string representation
    public let jsonString: String?

    /// Dictionary representation
    public let dictionary: [String: AnyCodableValue]

    enum CodingKeys: String, CodingKey {
        case locale
        case jsonString = "json_string"
        case data
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        locale = try container.decodeIfPresent(String.self, forKey: .locale) ?? "en"

        if let data = try container.decodeIfPresent([String: AnyCodableValue].self, forKey: .data) {
            dictionary = data
            if let jsonData = try? JSONSerialization.data(withJSONObject: data.mapValues { $0.value }, options: []),
               let json = String(data: jsonData, encoding: .utf8) {
                jsonString = json
            } else {
                jsonString = nil
            }
        } else {
            dictionary = [:]
            jsonString = try container.decodeIfPresent(String.self, forKey: .jsonString)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(locale, forKey: .locale)
        try container.encodeIfPresent(jsonString, forKey: .jsonString)
        try container.encode(dictionary, forKey: .data)
    }

    /// Get value for key
    public func value(forKey key: String) -> Any? {
        return dictionary[key]?.value
    }

    /// Get string value for key
    public func string(forKey key: String) -> String? {
        return dictionary[key]?.value as? String
    }

    /// Get int value for key
    public func int(forKey key: String) -> Int? {
        return dictionary[key]?.value as? Int
    }

    /// Get double value for key
    public func double(forKey key: String) -> Double? {
        return dictionary[key]?.value as? Double
    }

    /// Get bool value for key
    public func bool(forKey key: String) -> Bool? {
        return dictionary[key]?.value as? Bool
    }

    /// Get array value for key
    public func array(forKey key: String) -> [Any]? {
        return dictionary[key]?.value as? [Any]
    }

    /// Get dictionary value for key
    public func dictionary(forKey key: String) -> [String: Any]? {
        return dictionary[key]?.value as? [String: Any]
    }
}

// MARK: - Placement (Adapty Compatible)

/// Represents a placement (similar to AdaptyPlacement)
public struct MonetixPlacement: Codable, Sendable {
    /// Placement ID
    public let id: String

    /// Audience name
    public let audienceName: String

    /// Revision number
    public let revision: Int

    /// A/B test name if active
    public let abTestName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case audienceName = "audience_name"
        case revision
        case abTestName = "ab_test_name"
    }
}

// MARK: - Onboarding (Adapty Compatible)

/// Represents an onboarding screen configuration (similar to AdaptyOnboarding)
public struct MonetixOnboarding: Codable, Sendable {
    /// Placement ID
    public let placement: String

    /// Instance identity
    public let instanceIdentity: String

    /// Variation ID
    public let variationId: String?

    /// Onboarding name
    public let name: String

    /// Remote config
    public let remoteConfig: MonetixRemoteConfig?

    /// Whether has view configuration
    public let hasViewConfiguration: Bool

    enum CodingKeys: String, CodingKey {
        case placement
        case instanceIdentity = "instance_identity"
        case variationId = "variation_id"
        case name
        case remoteConfig = "remote_config"
        case hasViewConfiguration = "has_view_configuration"
    }
}

// MARK: - Fallback Paywalls

/// Fallback paywalls container
public struct MonetixFallbackPaywalls: Codable, Sendable {
    public let paywalls: [String: MonetixPaywall]
    public let version: Int

    public init(paywalls: [String: MonetixPaywall], version: Int = 1) {
        self.paywalls = paywalls
        self.version = version
    }

    /// Get paywall for placement
    public func paywall(forPlacement placementId: String) -> MonetixPaywall? {
        return paywalls[placementId]
    }
}
