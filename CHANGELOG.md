# Changelog

All notable changes to MonetixSDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-03

### Added
- Initial release of MonetixSDK
- Adapty-style API design for easy migration
- StoreKit 2 integration for native iOS purchases
- Async/await support with fallback to completion handlers
- User profile and subscription management
- Paywall and product fetching from backend
- Purchase flow with automatic receipt syncing
- Restore purchases functionality
- Built-in analytics event tracking
- Custom log handler support
- MonetixPaywallController base class for custom UIs
- MonetixPaywallControllerDelegate for purchase events
- MonetixAnalyticsDelegate for custom analytics integration
- Comprehensive error handling with MonetixError enum
- Support for iOS 15.0+ and macOS 12.0+
- Swift Package Manager support
- Complete documentation (README, USAGE_EXAMPLE, BACKEND_INTEGRATION)
- MIT License

### Core Features
- **Configuration Builder Pattern**: Fluent API for SDK setup
- **Singleton Pattern**: `Monetix.shared` for easy access
- **Automatic Transaction Observer**: Background monitoring of purchases
- **Profile Caching**: 5-minute cache for user profiles
- **Event Queue**: Automatic retry for failed analytics events
- **Platform Support**: iOS-specific UI components with macOS compatibility

### API Endpoints
- GET /users/{userId}/profile
- GET /access/check/{userId}
- GET /paywalls/{placementId}
- GET /paywalls/{paywallId}/products
- POST /purchases
- POST /purchases/restore
- POST /events
- POST /logs

### Developer Experience
- Full DocC documentation comments
- Example code in all documentation files
- Migration guide from Adapty
- Backend integration guide
- Type-safe API with Swift generics
- Comprehensive error messages

---

## [Unreleased]

### Planned for v1.1.0
- [ ] SwiftUI PaywallView components
- [ ] Combine framework support
- [ ] Offline event queue persistence
- [ ] Custom user attributes support
- [ ] Paywall presentation modifiers

### Planned for v1.2.0
- [ ] A/B test variant auto-assignment
- [ ] In-app paywall analytics dashboard
- [ ] Attribution integration (AppsFlyer, Adjust, etc.)
- [ ] Subscription cancellation flow
- [ ] Price localization helpers

### Planned for v2.0.0
- [ ] Android SDK (Kotlin)
- [ ] React Native bridge
- [ ] Flutter plugin
- [ ] Cross-platform analytics
- [ ] Unified dashboard

---

## Version History

- **1.0.0** (2026-01-03) - Initial release with full Adapty-compatible API

---

## Migration Guides

### From Adapty to MonetixSDK
See [USAGE_EXAMPLE.md](USAGE_EXAMPLE.md) for a complete migration guide.

**Quick migration steps:**
1. Replace `import Adapty` with `import MonetixSDK`
2. Replace `Adapty.shared` with `Monetix.shared`
3. Update `AdaptyConfiguration` to `MonetixConfiguration`
4. Update `AdaptyPaywallControllerDelegate` to `MonetixPaywallControllerDelegate`
5. Change `profile.accessLevels["premium"]?.isActive` to `profile.isPremium`
6. Update backend URL in configuration

---

## Breaking Changes

None yet - first release!

---

## Deprecations

None yet - first release!

---

## Security Updates

- All API requests use HTTPS only
- API key authentication on all endpoints
- StoreKit 2 transaction verification
- JWS signature validation for Apple receipts

---

## Contributors

- Monetix Team - Initial development
- Community contributors welcome!

---

## Support

For questions, bug reports, or feature requests:
- GitHub Issues: https://github.com/your-org/MonetixSDK/issues
- Email: support@monetix.app
- Documentation: https://github.com/your-org/MonetixSDK

---

**Note**: This project follows semantic versioning. Backward compatibility is maintained within major versions.
