//
//  MonetixError.swift
//  MonetixSDK
//
//  Created by MonetixSDK
//

import Foundation

/// Monetix SDK error types
public enum MonetixError: Error {
    case notActivated
    case invalidConfiguration
    case invalidAPIKey
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case purchaseFailed(Error)
    case purchaseCancelled
    case restoreFailed(Error)
    case productNotFound
    case paywallNotFound
    case userNotFound
    case storeKitError(Error)
    case unknownError(String)

    public var errorCode: Int {
        switch self {
        case .notActivated: return 1000
        case .invalidConfiguration: return 1001
        case .invalidAPIKey: return 1002
        case .networkError: return 2000
        case .invalidResponse: return 2001
        case .decodingError: return 2002
        case .purchaseFailed: return 3000
        case .purchaseCancelled: return 3001
        case .restoreFailed: return 3002
        case .productNotFound: return 4000
        case .paywallNotFound: return 4001
        case .userNotFound: return 4002
        case .storeKitError: return 5000
        case .unknownError: return 9999
        }
    }

    public var localizedDescription: String {
        switch self {
        case .notActivated:
            return "Monetix SDK is not activated. Call Monetix.activate() first."
        case .invalidConfiguration:
            return "Invalid Monetix configuration."
        case .invalidAPIKey:
            return "Invalid API key provided."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid server response."
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .purchaseFailed(let error):
            return "Purchase failed: \(error.localizedDescription)"
        case .purchaseCancelled:
            return "Purchase was cancelled by user."
        case .restoreFailed(let error):
            return "Restore failed: \(error.localizedDescription)"
        case .productNotFound:
            return "Product not found."
        case .paywallNotFound:
            return "Paywall not found."
        case .userNotFound:
            return "User not found."
        case .storeKitError(let error):
            return "StoreKit error: \(error.localizedDescription)"
        case .unknownError(let message):
            return "Unknown error: \(message)"
        }
    }
}

/// Log levels for Monetix logging
public enum MonetixLogLevel: String, Sendable {
    case error = "error"
    case warn = "warn"
    case info = "info"
    case verbose = "verbose"
    case debug = "debug"
}
