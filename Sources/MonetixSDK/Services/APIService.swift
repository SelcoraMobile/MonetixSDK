//
//  APIService.swift
//  MonetixSDK
//
//  Created by MonetixSDK
//

import Foundation

/// API Service for communicating with Monetix backend
internal class APIService {
    static let shared = APIService()

    private var configuration: MonetixConfiguration?
    private let session: URLSession
    private var logHandler: ((MonetixLogLevel, String, String) -> Void)?

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    func configure(with configuration: MonetixConfiguration) {
        self.configuration = configuration
    }

    func setLogHandler(_ handler: @escaping (MonetixLogLevel, String, String) -> Void) {
        self.logHandler = handler
    }

    private func log(_ level: MonetixLogLevel, _ message: String, function: String = #function) {
        logHandler?(level, message, function)
    }

    // MARK: - User Profile

    /// Get user profile (Adapty compatible)
    func getProfile(userId: String) async throws -> MonetixProfile {
        guard configuration != nil else {
            throw MonetixError.notActivated
        }

        let endpoint = "/users/\(userId)/profile"
        return try await request(endpoint: endpoint, method: "GET")
    }

    /// Sync user with backend
    func syncUser(userId: String, attributes: [String: Any]? = nil) async throws -> UserSyncResponse {
        guard configuration != nil else {
            throw MonetixError.notActivated
        }

        var body: [String: Any] = ["user_id": userId]
        if let attributes = attributes {
            body["attributes"] = attributes
        }

        let endpoint = "/users/sync"
        return try await request(endpoint: endpoint, method: "POST", body: body)
    }

    /// Update user profile
    func updateProfile(userId: String, params: MonetixProfileParameters) async throws -> MonetixProfile {
        guard configuration != nil else {
            throw MonetixError.notActivated
        }

        var attributes: [String: Any] = [:]
        if let email = params.email { attributes["email"] = email }
        if let phoneNumber = params.phoneNumber { attributes["phone_number"] = phoneNumber }
        if let firstName = params.firstName { attributes["first_name"] = firstName }
        if let lastName = params.lastName { attributes["last_name"] = lastName }
        if let gender = params.gender { attributes["gender"] = gender }
        if let birthday = params.birthday {
            let formatter = ISO8601DateFormatter()
            attributes["birthday"] = formatter.string(from: birthday)
        }
        if let customAttributes = params.customAttributes {
            attributes["custom_attributes"] = customAttributes
        }
        if let facebookAnonymousId = params.facebookAnonymousId { attributes["facebook_anonymous_id"] = facebookAnonymousId }
        if let amplitudeUserId = params.amplitudeUserId { attributes["amplitude_user_id"] = amplitudeUserId }
        if let amplitudeDeviceId = params.amplitudeDeviceId { attributes["amplitude_device_id"] = amplitudeDeviceId }
        if let mixpanelUserId = params.mixpanelUserId { attributes["mixpanel_user_id"] = mixpanelUserId }
        if let appmetricaProfileId = params.appmetricaProfileId { attributes["appmetrica_profile_id"] = appmetricaProfileId }
        if let appmetricaDeviceId = params.appmetricaDeviceId { attributes["appmetrica_device_id"] = appmetricaDeviceId }
        if let oneSignalPlayerId = params.oneSignalPlayerId { attributes["onesignal_player_id"] = oneSignalPlayerId }
        if let oneSignalSubscriptionId = params.oneSignalSubscriptionId { attributes["onesignal_subscription_id"] = oneSignalSubscriptionId }
        if let pushwooshHWID = params.pushwooshHWID { attributes["pushwoosh_hwid"] = pushwooshHWID }
        if let firebaseAppInstanceId = params.firebaseAppInstanceId { attributes["firebase_app_instance_id"] = firebaseAppInstanceId }
        if let airbridgeDeviceId = params.airbridgeDeviceId { attributes["airbridge_device_id"] = airbridgeDeviceId }
        if let attStatus = params.appTrackingTransparencyStatus { attributes["att_status"] = attStatus }
        if let analyticsDisabled = params.analyticsDisabled { attributes["analytics_disabled"] = analyticsDisabled }

        let body: [String: Any] = ["attributes": attributes]
        let endpoint = "/users/\(userId)/attributes"
        let _: EmptyResponse = try await request(endpoint: endpoint, method: "PUT", body: body)

        // Fetch and return updated profile
        return try await getProfile(userId: userId)
    }

    /// Identify user (link anonymous user to customer user ID)
    func identify(userId: String, customerUserId: String) async throws -> MonetixProfile {
        guard configuration != nil else {
            throw MonetixError.notActivated
        }

        let body: [String: Any] = [
            "user_id": userId,
            "customer_user_id": customerUserId
        ]

        let endpoint = "/users/identify"
        return try await request(endpoint: endpoint, method: "POST", body: body)
    }

    /// Logout user
    func logout(userId: String) async throws {
        guard configuration != nil else {
            throw MonetixError.notActivated
        }

        let endpoint = "/users/\(userId)/logout"
        let _: EmptyResponse = try await request(endpoint: endpoint, method: "POST")
    }

    // MARK: - Access Check

    /// Check premium access
    func checkAccess(userId: String) async throws -> AccessCheckResponse {
        guard configuration != nil else {
            throw MonetixError.notActivated
        }

        let endpoint = "/access/check/\(userId)"
        return try await request(endpoint: endpoint, method: "GET")
    }

    // MARK: - Paywalls

    /// Get paywall by placement ID (with A/B test support)
    func getPaywall(placementId: String, userId: String, locale: String = "en") async throws -> MonetixPaywall {
        guard configuration != nil else {
            throw MonetixError.notActivated
        }

        // Use a custom character set that properly encodes query parameter values
        var queryAllowed = CharacterSet.urlQueryAllowed
        queryAllowed.remove(charactersIn: "&=+")
        let encodedPlacement = placementId.addingPercentEncoding(withAllowedCharacters: queryAllowed) ?? placementId
        let encodedUserId = userId.addingPercentEncoding(withAllowedCharacters: queryAllowed) ?? userId
        let encodedLocale = locale.addingPercentEncoding(withAllowedCharacters: queryAllowed) ?? locale
        let endpoint = "/paywalls/get-paywall?placement=\(encodedPlacement)&user_id=\(encodedUserId)&locale=\(encodedLocale)"

        let response: PaywallResponse = try await request(endpoint: endpoint, method: "GET")
        return response.toPaywall()
    }

    /// Set variation ID for a transaction (A/B test attribution)
    func setVariationId(variationId: String, transactionId: String, userId: String) async throws {
        guard configuration != nil else {
            throw MonetixError.notActivated
        }

        let body: [String: Any] = [
            "user_id": userId,
            "transaction_id": transactionId,
            "variation_id": variationId
        ]

        let endpoint = "/paywalls/post-purchase"
        let _: EmptyResponse = try await request(endpoint: endpoint, method: "POST", body: body)
    }

    // MARK: - Purchases

    /// Report purchase to backend
    func reportPurchase(
        userId: String,
        productId: String,
        transactionId: String,
        originalTransactionId: String,
        price: Decimal,
        currency: String,
        variationId: String? = nil,
        paywallName: String? = nil
    ) async throws -> MonetixProfile {
        guard configuration != nil else {
            throw MonetixError.notActivated
        }

        var body: [String: Any] = [
            "user_id": userId,
            "product_id": productId,
            "transaction_id": transactionId,
            "original_transaction_id": originalTransactionId,
            "price": NSDecimalNumber(decimal: price).doubleValue,
            "currency": currency
        ]

        if let variationId = variationId {
            body["variation_id"] = variationId
        }
        if let paywallName = paywallName {
            body["paywall_name"] = paywallName
        }

        let endpoint = "/purchases/report"
        return try await request(endpoint: endpoint, method: "POST", body: body)
    }

    /// Sync receipt with backend (for transaction observation)
    func syncReceipt(
        userId: String,
        productId: String,
        transactionId: String,
        originalTransactionId: String,
        receiptData: String
    ) async throws {
        guard configuration != nil else {
            throw MonetixError.notActivated
        }

        let body: [String: Any] = [
            "user_id": userId,
            "product_id": productId,
            "transaction_id": transactionId,
            "original_transaction_id": originalTransactionId,
            "receipt": receiptData
        ]

        let endpoint = "/purchases/sync-receipt"
        let _: EmptyResponse = try await request(endpoint: endpoint, method: "POST", body: body)
    }

    /// Restore purchases
    func restorePurchases(userId: String, transactions: [[String: Any]]) async throws -> MonetixProfile {
        guard configuration != nil else {
            throw MonetixError.notActivated
        }

        let body: [String: Any] = [
            "user_id": userId,
            "transactions": transactions
        ]

        let endpoint = "/purchases/restore"
        return try await request(endpoint: endpoint, method: "POST", body: body)
    }

    // MARK: - Analytics

    /// Send event to backend
    func trackEvent(
        userId: String,
        eventName: String,
        metadata: [String: Any]? = nil
    ) async throws {
        guard configuration != nil else {
            throw MonetixError.notActivated
        }

        var body: [String: Any] = [
            "user_id": userId,
            "event_name": eventName,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]

        if let metadata = metadata {
            body["metadata"] = metadata
        }

        let endpoint = "/analytics/track-event"
        let _: EmptyResponse = try await request(endpoint: endpoint, method: "POST", body: body)
    }

    /// Track multiple events in batch
    func trackEvents(events: [[String: Any]]) async throws {
        guard configuration != nil else {
            throw MonetixError.notActivated
        }

        let body: [String: Any] = ["events": events]
        let endpoint = "/analytics/track-events"
        let _: EmptyResponse = try await request(endpoint: endpoint, method: "POST", body: body)
    }

    // MARK: - Attribution

    /// Update attribution data
    func updateAttribution(userId: String, attribution: MonetixAttributionData) async throws {
        guard configuration != nil else {
            throw MonetixError.notActivated
        }

        var body: [String: Any] = [
            "user_id": userId,
            "source": attribution.source.rawValue,
            "attribution": attribution.attribution
        ]

        if let networkUserId = attribution.networkUserId {
            body["network_user_id"] = networkUserId
        }

        let endpoint = "/users/\(userId)/attribution"
        let _: EmptyResponse = try await request(endpoint: endpoint, method: "POST", body: body)
    }

    // MARK: - Generic Request

    private func request<T: Decodable>(
        endpoint: String,
        method: String,
        body: [String: Any]? = nil
    ) async throws -> T {
        guard let config = configuration else {
            throw MonetixError.notActivated
        }

        let urlString = config.environment.baseURL + endpoint
        guard let url = URL(string: urlString) else {
            throw MonetixError.invalidConfiguration
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(config.apiKey, forHTTPHeaderField: "X-Api-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("MonetixSDK/1.0.0", forHTTPHeaderField: "User-Agent")
        request.setValue("ios", forHTTPHeaderField: "X-Platform")

        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        log(.debug, "API Request: \(method) \(urlString)")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw MonetixError.invalidResponse
            }

            log(.debug, "API Response: \(httpResponse.statusCode)")

            guard (200...299).contains(httpResponse.statusCode) else {
                if let errorMessage = String(data: data, encoding: .utf8) {
                    log(.error, "API Error: \(errorMessage)")
                }

                switch httpResponse.statusCode {
                case 401:
                    throw MonetixError.invalidAPIKey
                case 404:
                    throw MonetixError.paywallNotFound
                default:
                    throw MonetixError.networkError(
                        NSError(domain: "MonetixAPI", code: httpResponse.statusCode, userInfo: [
                            NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"
                        ])
                    )
                }
            }

            // Handle empty responses
            if data.isEmpty || T.self == EmptyResponse.self {
                guard let emptyResponse = EmptyResponse() as? T else {
                    throw MonetixError.decodingError(NSError(domain: "MonetixAPI", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "Cannot cast EmptyResponse to expected type"
                    ]))
                }
                return emptyResponse
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)

                // Try ISO8601 with fractional seconds first
                let iso8601Formatter = ISO8601DateFormatter()
                iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = iso8601Formatter.date(from: dateString) {
                    return date
                }

                // Try without fractional seconds
                iso8601Formatter.formatOptions = [.withInternetDateTime]
                if let date = iso8601Formatter.date(from: dateString) {
                    return date
                }

                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Cannot decode date: \(dateString)"
                )
            }

            // Try to decode the response
            do {
                // First try to decode as APIResponse wrapper
                let apiResponse = try decoder.decode(APIResponse<T>.self, from: data)
                if apiResponse.success, let responseData = apiResponse.data {
                    return responseData
                } else if let error = apiResponse.error {
                    throw MonetixError.unknownError(error.message)
                }
            } catch {
                // If that fails, try to decode directly
                return try decoder.decode(T.self, from: data)
            }

            throw MonetixError.decodingError(NSError(domain: "MonetixAPI", code: -1, userInfo: nil))

        } catch let error as MonetixError {
            throw error
        } catch let error as DecodingError {
            log(.error, "Decoding error: \(error)")
            throw MonetixError.decodingError(error)
        } catch {
            log(.error, "Network error: \(error.localizedDescription)")
            throw MonetixError.networkError(error)
        }
    }
}

// MARK: - Response Types

private struct EmptyResponse: Codable {}

private struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let error: APIError?
}

private struct APIError: Decodable {
    let code: String
    let message: String
}

struct UserSyncResponse: Codable {
    let userId: String
    let id: String
    let syncedAt: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case id
        case syncedAt
    }
}

struct AccessCheckResponse: Codable {
    let userId: String
    let hasPremium: Bool
    let subscriptions: [SubscriptionInfo]

    struct SubscriptionInfo: Codable {
        let originalTransactionId: String
        let productId: String
        let productName: String
        let status: String
        let expiresAt: Date?
        let autoRenewStatus: Bool
        let isInBillingRetry: Bool

        enum CodingKeys: String, CodingKey {
            case originalTransactionId = "original_transaction_id"
            case productId = "product_id"
            case productName
            case status
            case expiresAt = "expires_at"
            case autoRenewStatus = "auto_renew_status"
            case isInBillingRetry = "is_in_billing_retry"
        }
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case hasPremium
        case subscriptions
    }
}

struct PaywallResponse: Codable {
    let paywall: PaywallData
    let abTest: ABTestData?
    let metadata: PaywallMetadata?

    struct PaywallData: Codable {
        let id: String
        let name: String
        let config: [String: AnyCodableValue]?
        let products: [ProductData]

        struct ProductData: Codable {
            let id: String
            let appleId: String
            let name: String
            let type: String
            let price: Decimal?

            enum CodingKeys: String, CodingKey {
                case id
                case appleId = "apple_id"
                case name
                case type
                case price
            }
        }
    }

    struct ABTestData: Codable {
        let testId: String
        let testName: String
        let variantId: String
        let variantName: String
        let isControl: Bool

        enum CodingKeys: String, CodingKey {
            case testId = "testId"
            case testName
            case variantId = "variant_id"
            case variantName
            case isControl = "is_control"
        }
    }

    struct PaywallMetadata: Codable {
        let timestamp: String
        let placement: String
        let userId: String

        enum CodingKeys: String, CodingKey {
            case timestamp
            case placement
            case userId = "user_id"
        }
    }

    func toPaywall() -> MonetixPaywall {
        let vendorProductIds = paywall.products.map { $0.appleId }

        // Create remote config if available
        var remoteConfig: MonetixRemoteConfig? = nil
        if let config = paywall.config, !config.isEmpty {
            // We'll create a simple remote config safely
            if let jsonData = try? JSONSerialization.data(withJSONObject: config.mapValues { $0.value }, options: []),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                // Escape the JSON string properly for embedding
                let escapedJsonString = jsonString.replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "\"", with: "\\\"")
                let remoteConfigJson = """
                {
                    "locale": "en",
                    "json_string": "\(escapedJsonString)",
                    "data": {}
                }
                """
                if let remoteConfigData = remoteConfigJson.data(using: .utf8) {
                    remoteConfig = try? JSONDecoder().decode(MonetixRemoteConfig.self, from: remoteConfigData)
                }
            }
        }

        // Create paywall directly using memberwise initializer instead of unsafe JSON
        return MonetixPaywall(
            id: paywall.id,
            placementId: metadata?.placement ?? "",
            instanceIdentity: UUID().uuidString,
            variationId: abTest?.variantId,
            name: paywall.name,
            abTestName: abTest?.testName,
            revision: 1,
            locale: "en",
            hasViewConfiguration: false,
            vendorProductIds: vendorProductIds,
            products: [],
            remoteConfig: remoteConfig
        )
    }
}
