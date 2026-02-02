//
//  UserManager.swift
//  MonetixSDK
//
//  Created by MonetixSDK
//

import Foundation

/// Manages user profile and premium status
internal actor UserManager {
    static let shared = UserManager()

    private var cachedProfile: MonetixProfile?
    private var lastProfileFetch: Date?
    private let cacheExpiration: TimeInterval = 300 // 5 minutes
    private var logHandler: ((MonetixLogLevel, String, String) -> Void)?

    private init() {}

    func setLogHandler(_ handler: @escaping (MonetixLogLevel, String, String) -> Void) {
        self.logHandler = handler
    }

    private func log(_ level: MonetixLogLevel, _ message: String, function: String = #function) {
        logHandler?(level, message, function)
    }

    // MARK: - Profile Management

    /// Get user profile (with caching)
    func getProfile(userId: String, forceRefresh: Bool = false) async throws -> MonetixProfile {
        // Check cache first
        if !forceRefresh,
           let cached = cachedProfile,
           let lastFetch = lastProfileFetch,
           Date().timeIntervalSince(lastFetch) < cacheExpiration {
            log(.debug, "Returning cached profile")
            return cached
        }

        log(.info, "Fetching user profile from backend")

        do {
            let profile = try await APIService.shared.getProfile(userId: userId)
            cachedProfile = profile
            lastProfileFetch = Date()
            log(.info, "Profile fetched successfully. isPremium: \(profile.isPremium)")
            return profile
        } catch {
            log(.error, "Failed to fetch profile: \(error)")
            throw error
        }
    }

    /// Check premium access
    func checkAccess(userId: String) async throws -> AccessCheckResponse {
        log(.info, "Checking premium access")

        do {
            let accessResponse = try await APIService.shared.checkAccess(userId: userId)
            log(.info, "Access checked. hasPremium: \(accessResponse.hasPremium)")
            return accessResponse
        } catch {
            log(.error, "Failed to check access: \(error)")
            throw error
        }
    }

    /// Check if user has premium (convenience method)
    func isPremium(userId: String) async -> Bool {
        do {
            let profile = try await getProfile(userId: userId)
            return profile.isPremium
        } catch {
            log(.error, "Failed to check premium status: \(error)")
            return false
        }
    }

    /// Get active access level
    func getActiveAccessLevel(userId: String) async -> MonetixAccessLevel? {
        do {
            let profile = try await getProfile(userId: userId)
            return profile.accessLevels.values.first { $0.isActive }
        } catch {
            log(.error, "Failed to get access level: \(error)")
            return nil
        }
    }

    /// Get original transaction ID (useful for backend integration)
    func getOriginalTransactionId(userId: String) async -> String? {
        do {
            let profile = try await getProfile(userId: userId)
            return profile.subscriptions.values.first?.vendorOriginalTransactionId
        } catch {
            log(.error, "Failed to get original transaction ID: \(error)")
            return nil
        }
    }

    /// Clear cached profile
    func clearCache() {
        log(.debug, "Clearing profile cache")
        cachedProfile = nil
        lastProfileFetch = nil
    }

    /// Update cache with new profile
    func updateCache(profile: MonetixProfile) {
        log(.debug, "Updating profile cache")
        cachedProfile = profile
        lastProfileFetch = Date()
    }
}
