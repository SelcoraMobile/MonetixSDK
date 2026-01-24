//
//  MonetixUser.swift
//  MonetixSDK
//
//  Created by MonetixSDK
//

import Foundation

// MARK: - Profile (Adapty Compatible)

/// Represents a user profile (similar to AdaptyProfile)
public struct MonetixProfile: Codable, Sendable {
    /// Unique profile identifier
    public let profileId: String

    /// Custom user identifier (set via identify)
    public let customerUserId: String?

    /// Access levels dictionary (key is access level ID)
    public let accessLevels: [String: MonetixAccessLevel]

    /// Subscriptions dictionary (key is vendor product ID)
    public let subscriptions: [String: MonetixSubscription]

    /// Non-subscription purchases (key is vendor product ID)
    public let nonSubscriptions: [String: [MonetixNonSubscription]]

    /// Custom user attributes
    public let customAttributes: [String: AnyCodableValue]

    /// Convenience property to check if user has any active access level
    public var isPremium: Bool {
        return accessLevels.values.contains { $0.isActive }
    }

    enum CodingKeys: String, CodingKey {
        case profileId = "profile_id"
        case customerUserId = "customer_user_id"
        case accessLevels = "access_levels"
        case subscriptions
        case nonSubscriptions = "non_subscriptions"
        case customAttributes = "custom_attributes"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        profileId = try container.decode(String.self, forKey: .profileId)
        customerUserId = try container.decodeIfPresent(String.self, forKey: .customerUserId)
        accessLevels = try container.decodeIfPresent([String: MonetixAccessLevel].self, forKey: .accessLevels) ?? [:]
        subscriptions = try container.decodeIfPresent([String: MonetixSubscription].self, forKey: .subscriptions) ?? [:]
        nonSubscriptions = try container.decodeIfPresent([String: [MonetixNonSubscription]].self, forKey: .nonSubscriptions) ?? [:]
        customAttributes = try container.decodeIfPresent([String: AnyCodableValue].self, forKey: .customAttributes) ?? [:]
    }
}

// MARK: - Access Level (Adapty Compatible)

/// Represents an access level (similar to AdaptyProfile.AccessLevel)
public struct MonetixAccessLevel: Codable, Sendable {
    /// Access level identifier
    public let id: String

    /// Whether access is currently active
    public let isActive: Bool

    /// Product ID that granted this access
    public let vendorProductId: String

    /// Store that processed the purchase (app_store, play_store, stripe)
    public let store: String

    /// When the access was first activated
    public let activatedAt: Date

    /// When the current period started
    public let startsAt: Date?

    /// When the access was last renewed
    public let renewedAt: Date?

    /// When the access expires (nil for lifetime)
    public let expiresAt: Date?

    /// Whether this is a lifetime access
    public let isLifetime: Bool

    /// Whether the subscription will renew
    public let willRenew: Bool

    /// Whether the subscription is in grace period
    public let isInGracePeriod: Bool

    /// When the user unsubscribed (turned off auto-renew)
    public let unsubscribedAt: Date?

    /// When billing issue was detected
    public let billingIssueDetectedAt: Date?

    /// Cancellation reason
    public let cancellationReason: String?

    /// Whether this purchase was refunded
    public let isRefund: Bool

    /// Active introductory offer type
    public let activeIntroductoryOfferType: String?

    /// Active promotional offer type
    public let activePromotionalOfferType: String?

    /// Active promotional offer ID
    public let activePromotionalOfferId: String?

    /// Offer identifier
    public let offerId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case isActive = "is_active"
        case vendorProductId = "vendor_product_id"
        case store
        case activatedAt = "activated_at"
        case startsAt = "starts_at"
        case renewedAt = "renewed_at"
        case expiresAt = "expires_at"
        case isLifetime = "is_lifetime"
        case willRenew = "will_renew"
        case isInGracePeriod = "is_in_grace_period"
        case unsubscribedAt = "unsubscribed_at"
        case billingIssueDetectedAt = "billing_issue_detected_at"
        case cancellationReason = "cancellation_reason"
        case isRefund = "is_refund"
        case activeIntroductoryOfferType = "active_introductory_offer_type"
        case activePromotionalOfferType = "active_promotional_offer_type"
        case activePromotionalOfferId = "active_promotional_offer_id"
        case offerId = "offer_id"
    }
}

// MARK: - Subscription (Adapty Compatible)

/// Represents a subscription (similar to AdaptyProfile.Subscription)
public struct MonetixSubscription: Codable, Sendable {
    /// Store that processed the purchase
    public let store: String

    /// Product ID from the store
    public let vendorProductId: String

    /// Transaction ID from the store
    public let vendorTransactionId: String

    /// Original transaction ID (for renewals)
    public let vendorOriginalTransactionId: String

    /// Whether subscription is currently active
    public let isActive: Bool

    /// Whether this is a lifetime subscription
    public let isLifetime: Bool

    /// When the subscription was first activated
    public let activatedAt: Date

    /// When the subscription was last renewed
    public let renewedAt: Date?

    /// When the subscription expires
    public let expiresAt: Date?

    /// When the current period started
    public let startsAt: Date?

    /// When user unsubscribed
    public let unsubscribedAt: Date?

    /// When billing issue was detected
    public let billingIssueDetectedAt: Date?

    /// Whether subscription will renew
    public let willRenew: Bool

    /// Whether in grace period
    public let isInGracePeriod: Bool

    /// Cancellation reason
    public let cancellationReason: String?

    /// Whether this was refunded
    public let isRefund: Bool

    /// Active introductory offer type
    public let activeIntroductoryOfferType: String?

    /// Active promotional offer type
    public let activePromotionalOfferType: String?

    /// Active promotional offer ID
    public let activePromotionalOfferId: String?

    /// Offer identifier
    public let offerId: String?

    /// Whether this is a sandbox transaction
    public let isSandbox: Bool

    enum CodingKeys: String, CodingKey {
        case store
        case vendorProductId = "vendor_product_id"
        case vendorTransactionId = "vendor_transaction_id"
        case vendorOriginalTransactionId = "vendor_original_transaction_id"
        case isActive = "is_active"
        case isLifetime = "is_lifetime"
        case activatedAt = "activated_at"
        case renewedAt = "renewed_at"
        case expiresAt = "expires_at"
        case startsAt = "starts_at"
        case unsubscribedAt = "unsubscribed_at"
        case billingIssueDetectedAt = "billing_issue_detected_at"
        case willRenew = "will_renew"
        case isInGracePeriod = "is_in_grace_period"
        case cancellationReason = "cancellation_reason"
        case isRefund = "is_refund"
        case activeIntroductoryOfferType = "active_introductory_offer_type"
        case activePromotionalOfferType = "active_promotional_offer_type"
        case activePromotionalOfferId = "active_promotional_offer_id"
        case offerId = "offer_id"
        case isSandbox = "is_sandbox"
    }
}

// MARK: - Non-Subscription (Adapty Compatible)

/// Represents a non-subscription purchase (similar to AdaptyProfile.NonSubscription)
public struct MonetixNonSubscription: Codable, Sendable {
    /// Unique purchase identifier
    public let purchaseId: String

    /// Product ID from the store
    public let vendorProductId: String

    /// Transaction ID from the store
    public let vendorTransactionId: String

    /// Store that processed the purchase
    public let store: String

    /// When the purchase was made
    public let purchasedAt: Date

    /// Whether this was refunded
    public let isRefund: Bool

    /// Whether this is a consumable product
    public let isConsumable: Bool

    /// Whether this is a sandbox transaction
    public let isSandbox: Bool

    enum CodingKeys: String, CodingKey {
        case purchaseId = "purchase_id"
        case vendorProductId = "vendor_product_id"
        case vendorTransactionId = "vendor_transaction_id"
        case store
        case purchasedAt = "purchased_at"
        case isRefund = "is_refund"
        case isConsumable = "is_consumable"
        case isSandbox = "is_sandbox"
    }
}

// MARK: - Profile Update Parameters

/// Parameters for updating user profile (similar to AdaptyProfileParameters)
public struct MonetixProfileParameters {
    public var email: String?
    public var phoneNumber: String?
    public var facebookAnonymousId: String?
    public var amplitudeUserId: String?
    public var amplitudeDeviceId: String?
    public var mixpanelUserId: String?
    public var appmetricaProfileId: String?
    public var appmetricaDeviceId: String?
    public var oneSignalPlayerId: String?
    public var oneSignalSubscriptionId: String?
    public var pushwooshHWID: String?
    public var firebaseAppInstanceId: String?
    public var airbridgeDeviceId: String?
    public var appTrackingTransparencyStatus: UInt?
    public var firstName: String?
    public var lastName: String?
    public var gender: String?
    public var birthday: Date?
    public var customAttributes: [String: Any]?
    public var analyticsDisabled: Bool?

    public init() {}

    /// Builder for fluent API
    public static func builder() -> Builder {
        return Builder()
    }

    public class Builder {
        private var params = MonetixProfileParameters()

        public func with(email: String) -> Builder {
            params.email = email
            return self
        }

        public func with(phoneNumber: String) -> Builder {
            params.phoneNumber = phoneNumber
            return self
        }

        public func with(firstName: String) -> Builder {
            params.firstName = firstName
            return self
        }

        public func with(lastName: String) -> Builder {
            params.lastName = lastName
            return self
        }

        public func with(gender: String) -> Builder {
            params.gender = gender
            return self
        }

        public func with(birthday: Date) -> Builder {
            params.birthday = birthday
            return self
        }

        public func with(customAttributes: [String: Any]) -> Builder {
            params.customAttributes = customAttributes
            return self
        }

        public func with(analyticsDisabled: Bool) -> Builder {
            params.analyticsDisabled = analyticsDisabled
            return self
        }

        public func with(facebookAnonymousId: String) -> Builder {
            params.facebookAnonymousId = facebookAnonymousId
            return self
        }

        public func with(amplitudeUserId: String) -> Builder {
            params.amplitudeUserId = amplitudeUserId
            return self
        }

        public func with(amplitudeDeviceId: String) -> Builder {
            params.amplitudeDeviceId = amplitudeDeviceId
            return self
        }

        public func with(mixpanelUserId: String) -> Builder {
            params.mixpanelUserId = mixpanelUserId
            return self
        }

        public func with(appmetricaProfileId: String) -> Builder {
            params.appmetricaProfileId = appmetricaProfileId
            return self
        }

        public func with(appmetricaDeviceId: String) -> Builder {
            params.appmetricaDeviceId = appmetricaDeviceId
            return self
        }

        public func with(oneSignalPlayerId: String) -> Builder {
            params.oneSignalPlayerId = oneSignalPlayerId
            return self
        }

        public func with(oneSignalSubscriptionId: String) -> Builder {
            params.oneSignalSubscriptionId = oneSignalSubscriptionId
            return self
        }

        public func with(pushwooshHWID: String) -> Builder {
            params.pushwooshHWID = pushwooshHWID
            return self
        }

        public func with(firebaseAppInstanceId: String) -> Builder {
            params.firebaseAppInstanceId = firebaseAppInstanceId
            return self
        }

        public func with(airbridgeDeviceId: String) -> Builder {
            params.airbridgeDeviceId = airbridgeDeviceId
            return self
        }

        public func with(appTrackingTransparencyStatus: UInt) -> Builder {
            params.appTrackingTransparencyStatus = appTrackingTransparencyStatus
            return self
        }

        public func build() -> MonetixProfileParameters {
            return params
        }
    }
}

// MARK: - AnyCodable Value (for custom attributes)

public struct AnyCodableValue: Codable, Sendable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let arrayValue = try? container.decode([AnyCodableValue].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodableValue].self) {
            value = dictValue.mapValues { $0.value }
        } else if container.decodeNil() {
            value = NSNull()
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported type"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodableValue($0) })
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues { AnyCodableValue($0) })
        case is NSNull:
            try container.encodeNil()
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unsupported type: \(type(of: value))"
                )
            )
        }
    }
}
