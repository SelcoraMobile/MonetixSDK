//
//  MonetixConfiguration.swift
//  MonetixSDK
//
//  Created by MonetixSDK
//

import Foundation

// MARK: - Monetix API Endpoints

/// Production API URL for Monetix SaaS
internal let MONETIX_PRODUCTION_URL = "https://api.monetix.selcoramobile.com/api"

/// Sandbox API URL for testing (same as production for now)
internal let MONETIX_SANDBOX_URL = "https://api.monetix.selcoramobile.com/api"

/// Configuration for Monetix SDK (Adapty compatible)
public struct MonetixConfiguration: Sendable {
    /// API key for authentication
    public let apiKey: String

    /// Custom user ID (optional, anonymous ID will be generated if not provided)
    public let userId: String?

    /// Backend environment
    public let environment: Environment

    /// Log level for SDK logs
    public let logLevel: MonetixLogLevel

    /// Observer mode - if true, SDK only tracks purchases but doesn't process them
    public let observerMode: Bool

    /// Custom backend URL (optional, uses default if not provided)
    public let customBackendURL: String?

    /// Whether to activate automatically on app start
    public let activateOnInit: Bool

    /// IDFA collection enabled (for attribution)
    public let idfaCollectionEnabled: Bool

    /// IP address collection enabled
    public let ipAddressCollectionEnabled: Bool

    public enum Environment: Sendable {
        case production
        case sandbox
        case custom(baseURL: String)

        var baseURL: String {
            switch self {
            case .production:
                return MONETIX_PRODUCTION_URL
            case .sandbox:
                return MONETIX_SANDBOX_URL
            case .custom(let url):
                return url
            }
        }
    }

    private init(
        apiKey: String,
        userId: String?,
        environment: Environment,
        logLevel: MonetixLogLevel,
        observerMode: Bool,
        customBackendURL: String?,
        activateOnInit: Bool,
        idfaCollectionEnabled: Bool,
        ipAddressCollectionEnabled: Bool
    ) {
        self.apiKey = apiKey
        self.userId = userId
        self.environment = environment
        self.logLevel = logLevel
        self.observerMode = observerMode
        self.customBackendURL = customBackendURL
        self.activateOnInit = activateOnInit
        self.idfaCollectionEnabled = idfaCollectionEnabled
        self.ipAddressCollectionEnabled = ipAddressCollectionEnabled
    }

    /// Builder for MonetixConfiguration (Adapty-style)
    public static func builder(withAPIKey apiKey: String) -> Builder {
        return Builder(apiKey: apiKey)
    }

    public class Builder {
        private let apiKey: String
        private var userId: String?
        private var environment: Environment = .production
        private var logLevel: MonetixLogLevel = .info
        private var observerMode: Bool = false
        private var customBackendURL: String?
        private var activateOnInit: Bool = true
        private var idfaCollectionEnabled: Bool = false
        private var ipAddressCollectionEnabled: Bool = true

        fileprivate init(apiKey: String) {
            self.apiKey = apiKey
        }

        /// Set custom user ID (Adapty compatible)
        public func with(customerUserId: String) -> Builder {
            self.userId = customerUserId
            return self
        }

        /// Set environment (production or sandbox)
        public func with(environment: Environment) -> Builder {
            self.environment = environment
            return self
        }

        /// Set custom backend URL
        public func with(backendBaseURL: String) -> Builder {
            self.customBackendURL = backendBaseURL
            self.environment = .custom(baseURL: backendBaseURL)
            return self
        }

        /// Set log level
        public func with(logLevel: MonetixLogLevel) -> Builder {
            self.logLevel = logLevel
            return self
        }

        /// Enable observer mode (purchases won't be processed by SDK)
        public func with(observerMode: Bool) -> Builder {
            self.observerMode = observerMode
            return self
        }

        /// Set whether to activate automatically on init
        public func with(activateOnInit: Bool) -> Builder {
            self.activateOnInit = activateOnInit
            return self
        }

        /// Enable IDFA collection for attribution
        public func with(idfaCollectionEnabled: Bool) -> Builder {
            self.idfaCollectionEnabled = idfaCollectionEnabled
            return self
        }

        /// Enable IP address collection
        public func with(ipAddressCollectionEnabled: Bool) -> Builder {
            self.ipAddressCollectionEnabled = ipAddressCollectionEnabled
            return self
        }

        /// Build the configuration
        public func build() -> MonetixConfiguration {
            return MonetixConfiguration(
                apiKey: apiKey,
                userId: userId,
                environment: environment,
                logLevel: logLevel,
                observerMode: observerMode,
                customBackendURL: customBackendURL,
                activateOnInit: activateOnInit,
                idfaCollectionEnabled: idfaCollectionEnabled,
                ipAddressCollectionEnabled: ipAddressCollectionEnabled
            )
        }
    }
}
