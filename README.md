# MonetixSDK - iOS Subscription Management

Professional subscription and monetization infrastructure for iOS applications. Built with **StoreKit 2**.

## Features

- **StoreKit 2 Integration** - Native iOS purchase handling
- **Async/Await & Completion Handlers** - Both modern and legacy support
- **Automatic Receipt Syncing** - Keep backend in sync with purchases
- **Built-in Analytics** - Track events, purchases, and user behavior
- **Paywall Management** - Remote config paywalls with A/B testing
- **Premium Access Control** - Easy subscription status checks
- **Swift Package Manager** - Easy installation

## Installation

### Swift Package Manager

Add MonetixSDK to your project via Xcode:

1. File → Add Package Dependencies
2. Enter the repository URL: `https://github.com/SelcoraMobile/MonetixSDK`
3. Select version and add to your target

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/SelcoraMobile/MonetixSDK", from: "1.0.0")
]
```

## Requirements

- iOS 15.0+
- macOS 12.0+ (Mac Catalyst)
- Xcode 15.0+
- Swift 5.9+

## Quick Start

### 1. Get Your API Key

Sign up at [Monetix Dashboard](https://dashboard.monetix.app) and create your app to get an API key.

### 2. Initialize the SDK

```swift
import MonetixSDK

@main
struct MyApp: App {
    init() {
        Task {
            do {
                let config = MonetixConfiguration
                    .builder(withAPIKey: "pk_live_your_api_key")
                    .with(environment: .production)
                    .build()

                try await Monetix.activate(with: config)
                print("Monetix activated!")
            } catch {
                print("Activation failed: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 3. Check Premium Status

```swift
let profile = try await Monetix.getProfile()

if profile.isPremium {
    // User has premium access
    showPremiumContent()
} else {
    // Show paywall
    showPaywall()
}
```

### 4. Show Paywall

```swift
func showPaywall() async {
    do {
        // Get paywall configuration
        let paywall = try await Monetix.getPaywall(placementId: "main")

        // Fetch StoreKit products
        let products = try await Monetix.getPaywallProducts(paywall: paywall)

        // Log paywall view for analytics
        Monetix.logShowPaywall(paywall)

        // Display your paywall UI with products
        presentPaywallUI(paywall: paywall, products: products)
    } catch {
        print("Failed to load paywall: \(error)")
    }
}
```

### 5. Make Purchase

```swift
func purchase(_ product: MonetixProduct) async {
    do {
        let result = try await Monetix.makePurchase(product: product)

        if let profile = result.profile, profile.isPremium {
            print("Purchase successful! User is now premium.")
            unlockPremiumFeatures()
        }
    } catch MonetixError.purchaseCancelled {
        // User cancelled - don't show error
    } catch {
        print("Purchase failed: \(error)")
    }
}
```

### 6. Restore Purchases

```swift
func restorePurchases() async {
    do {
        let profile = try await Monetix.restorePurchases()

        if profile.isPremium {
            print("Purchases restored!")
            unlockPremiumFeatures()
        } else {
            print("No purchases to restore")
        }
    } catch {
        print("Restore failed: \(error)")
    }
}
```

## Configuration Options

```swift
let config = MonetixConfiguration
    .builder(withAPIKey: "pk_live_xxxxx")
    .with(customerUserId: "user_123")    // Optional: Your user ID
    .with(environment: .production)       // .production or .sandbox
    .with(logLevel: .info)               // .error, .warn, .info, .debug, .verbose
    .with(observerMode: false)           // true = track only, don't process
    .build()
```

## User Identification

```swift
// After user logs in, link their purchases
try await Monetix.identify("your_user_id")

// On logout
try await Monetix.logout()
```

## Error Handling

```swift
do {
    let result = try await Monetix.makePurchase(product: product)
    // Handle success
} catch MonetixError.purchaseCancelled {
    // User cancelled - don't show error
} catch MonetixError.networkError(let error) {
    print("Network error: \(error)")
} catch {
    print("Error: \(error)")
}
```

## Documentation

For full documentation, visit the SDK Documentation section in your Monetix Dashboard.

## License

MIT License
