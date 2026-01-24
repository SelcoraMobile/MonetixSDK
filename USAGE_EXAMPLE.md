# 🎯 MonetixSDK - Adapty Tarzı Kullanım Örneği

Bu örnek, Adapty'den MonetixSDK'ya geçiş yapanlar için tam bir kullanım senaryosudur.

## 📱 Adapty ile Nasıl Kullanıyordunuz?

### Adapty Örneği (Önceki Kodunuz)

```swift
final class AdaptyService {
    static let shared = AdaptyService()
    var errorCallback: ((String) -> Void)?
    weak var analyticsDelegate: AdaptyAnalyticsDelegate?

    let configurationBuilder = AdaptyConfiguration
        .builder(withAPIKey: "public_live_VbAhCdX2.MVoqnpXmeSavXNf90qHD")
        .with(observerMode: false)
        .with(customerUserId: Config.UDID)
        .with(idfaCollectionDisabled: false)
        .with(ipAddressCollectionDisabled: false)

    func initialize() async {
        Adapty.setLogHandler { record in
            // Log handling
        }

        try? await Adapty.activate(with: configurationBuilder.build())
    }

    func checkUser(completion: @escaping (_ isPremium: Bool, _ originalTransactionId: String) -> ()) {
        Adapty.getProfile { result in
            switch result {
            case .success(let profile):
                let originalTransactionId = profile.subscriptions.values.first?.vendorOriginalTransactionId ?? ""
                let isPremium = profile.accessLevels["premium"]?.isActive ?? false
                completion(isPremium, originalTransactionId)
            case .failure:
                completion(false, "")
            }
        }
    }

    func openPaywall(placementId: String, view: UIViewController) {
        Adapty.getPaywall(placementId: placementId, locale: "en") { result in
            switch result {
            case .success(let paywall):
                // Handle paywall
            case .failure(let error):
                self.errorCallback?(error.localizedDescription)
            }
        }
    }
}
```

## 🚀 MonetixSDK ile Nasıl Kullanılır?

### MonetixService - Tam Adapty Benzeri Kullanım

```swift
import MonetixSDK
import UIKit

final class MonetixService {
    // MARK: - Properties

    static let shared = MonetixService()
    var errorCallback: ((String) -> Void)?
    weak var analyticsDelegate: MonetixAnalyticsDelegate?
    private weak var currentPaywallController: UIViewController?

    // MARK: - Initialization

    private init() {}

    // Configuration builder (Adapty benzeri)
    let configurationBuilder = MonetixConfiguration
        .builder(withAPIKey: "your-monetix-api-key-here")
        .with(observerMode: false)
        .with(customerUserId: "user-123") // Your user ID (UDID, Firebase ID, etc.)
        .with(environment: .production)
        .with(logLevel: .debug)

    // MARK: - Public Methods

    /// Initialize SDK (Adapty.activate() benzeri)
    func initialize() async {
        // Configure logging before activation
        Monetix.shared.setLogHandler { [weak self] level, message, function in
            // Log to console
            let emoji: String = switch level {
            case .error: "🔴"
            case .warn: "⚠️"
            case .info: "ℹ️"
            case .verbose: "📝"
            case .debug: "🔍"
            }

            debugPrint("\(emoji) Monetix [\(function)]: \(message)")

            // Optional: Send logs to your backend
            // self?.sendLogToBackend(description: message, level: level, function: function)
        }

        // Activate SDK
        do {
            try await Monetix.shared.activate(with: configurationBuilder.build())
            debugPrint("✅ Monetix SDK activated successfully")
        } catch {
            debugPrint("❌ Monetix activation failed: \(error)")
            errorCallback?(error.localizedDescription)
        }
    }

    /// Check user premium status (Adapty.getProfile() benzeri)
    func checkUser(completion: @escaping (_ isPremium: Bool, _ originalTransactionId: String) -> ()) {
        Monetix.shared.getProfile { result in
            switch result {
            case .success(let profile):
                let originalTransactionId = profile.subscription?.vendorOriginalTransactionId ?? ""
                let isPremium = profile.isPremium
                completion(isPremium, originalTransactionId)
            case .failure:
                completion(false, "")
            }
        }
    }

    /// Open paywall (Adapty.getPaywall() benzeri)
    func openPaywall(placementId: String, view: UIViewController) {
        let locale = Locale.current.identifier
        let localeCode = String(locale.prefix(2))

        Monetix.shared.getPaywall(placementId: placementId, locale: localeCode) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let paywall):
                self.handlePaywall(paywall: paywall, view: view)
            case .failure(let error):
                debugPrint("Failed to get paywall: \(error.localizedDescription)")
                self.errorCallback?(error.localizedDescription)
            }
        }
    }

    // MARK: - Private Methods

    private func handlePaywall(paywall: MonetixPaywall, view: UIViewController) {
        // Get products for paywall
        Monetix.shared.getPaywallProducts(paywall: paywall) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let products):
                self.displayPaywall(paywall: paywall, products: products, view: view)
            case .failure(let error):
                debugPrint("Failed to get products: \(error)")
                self.errorCallback?(error.localizedDescription)
            }
        }
    }

    private func displayPaywall(
        paywall: MonetixPaywall,
        products: [MonetixProduct],
        view: UIViewController
    ) {
        // You can use the default controller or create your custom one
        let controller = MonetixPaywallController(paywall: paywall, products: products)
        controller.delegate = PaywallDelegateHandler(
            paywall: paywall,
            analyticsDelegate: analyticsDelegate,
            errorCallback: errorCallback
        )

        currentPaywallController = controller

        // Log paywall show
        Monetix.shared.logShowPaywall(paywall)

        // Present
        controller.modalPresentationStyle = .overFullScreen
        controller.modalTransitionStyle = .coverVertical
        view.present(controller, animated: true)

        // Notify analytics
        analyticsDelegate?.onPaywallOpen(
            paywallName: paywall.name,
            isABTest: paywall.abTestName != nil,
            abTestName: paywall.abTestName
        )
    }

    /// Restore purchases (Adapty.restorePurchases() benzeri)
    func restorePurchases() {
        Monetix.shared.restorePurchases { [weak self] result in
            switch result {
            case .success(let profile):
                if profile.isPremium {
                    self?.analyticsDelegate?.onRestoreSuccess()
                    debugPrint("✅ Purchases restored successfully")
                } else {
                    debugPrint("⚠️ No active subscription found")
                }
            case .failure(let error):
                self?.errorCallback?(error.localizedDescription)
                debugPrint("❌ Restore failed: \(error)")
            }
        }
    }
}

// MARK: - PaywallDelegateHandler (AdaptyPaywallControllerDelegate benzeri)

private class PaywallDelegateHandler: NSObject, MonetixPaywallControllerDelegate {
    let paywall: MonetixPaywall
    weak var analyticsDelegate: MonetixAnalyticsDelegate?
    var errorCallback: ((String) -> Void)?

    init(
        paywall: MonetixPaywall,
        analyticsDelegate: MonetixAnalyticsDelegate?,
        errorCallback: ((String) -> Void)?
    ) {
        self.paywall = paywall
        self.analyticsDelegate = analyticsDelegate
        self.errorCallback = errorCallback
        super.init()
    }

    func paywallControllerDidStartPresenting(_ controller: MonetixPaywallController) {
        debugPrint("Paywall opened: \(paywall.name)")
    }

    func paywallControllerDidDismiss(_ controller: MonetixPaywallController) {
        debugPrint("Paywall closed")
        analyticsDelegate?.onPaywallClose()
    }

    func paywallController(
        _ controller: MonetixPaywallController,
        didFinishPurchase product: MonetixProduct,
        purchaseResult: MonetixPurchaseResult
    ) {
        guard let profile = purchaseResult.profile else { return }

        if profile.isPremium {
            let transactionId = profile.subscription?.vendorTransactionId ?? ""

            analyticsDelegate?.onPurchaseSuccess(
                purchaseTransactionId: transactionId,
                paywallName: paywall.placementId,
                productId: product.vendorProductId,
                isABTest: paywall.abTestName != nil,
                abTestName: paywall.abTestName ?? ""
            )

            // Dismiss paywall
            controller.dismiss(animated: true) {
                debugPrint("✅ Purchase completed successfully")
            }
        }
    }

    func paywallController(
        _ controller: MonetixPaywallController,
        didFailPurchase product: MonetixProduct,
        error: MonetixError
    ) {
        analyticsDelegate?.onPurchaseFailed(
            paywallName: paywall.placementId,
            isABTest: paywall.abTestName != nil,
            abTestName: paywall.abTestName ?? "",
            productCode: product.vendorProductId,
            errorCode: "\(error.errorCode)",
            errorDetail: error.localizedDescription
        )

        debugPrint("❌ Purchase failed: \(error)")
    }

    func paywallController(
        _ controller: MonetixPaywallController,
        didCancelPurchase product: MonetixProduct
    ) {
        debugPrint("⚠️ Purchase cancelled by user")
    }

    func paywallController(
        _ controller: MonetixPaywallController,
        didFinishRestoreWith profile: MonetixProfile
    ) {
        if profile.isPremium {
            analyticsDelegate?.onRestoreSuccess()
            controller.dismiss(animated: true) {
                debugPrint("✅ Restore successful")
            }
        } else {
            debugPrint("⚠️ No premium subscription found")
        }
    }

    func paywallController(
        _ controller: MonetixPaywallController,
        didFailRestoreWith error: MonetixError
    ) {
        errorCallback?(error.localizedDescription)
        debugPrint("❌ Restore failed: \(error)")
    }

    func paywallController(
        _ controller: MonetixPaywallController,
        didFailRenderingWith error: MonetixError
    ) {
        analyticsDelegate?.isNotVisiblePaywall(
            errorDetail: error.localizedDescription,
            paywallName: paywall.name
        )
        errorCallback?(error.localizedDescription)
    }
}
```

## 🔧 AppDelegate'de Kullanım

```swift
import UIKit
import MonetixSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // Initialize Monetix
        Task {
            await MonetixService.shared.initialize()
        }

        return true
    }
}
```

## 🎨 ViewController'da Kullanım

```swift
import UIKit

class OnboardingViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup analytics delegate
        MonetixService.shared.analyticsDelegate = self

        // Setup error callback
        MonetixService.shared.errorCallback = { [weak self] errorMessage in
            self?.showError(errorMessage)
        }
    }

    @IBAction func showPaywallButtonTapped(_ sender: UIButton) {
        // Show paywall for onboarding placement
        MonetixService.shared.openPaywall(placementId: "onboarding", view: self)
    }

    @IBAction func checkPremiumButtonTapped(_ sender: UIButton) {
        MonetixService.shared.checkUser { [weak self] isPremium, originalTransactionId in
            if isPremium {
                self?.unlockPremiumFeatures()
                print("Original Transaction ID: \(originalTransactionId)")
            } else {
                self?.showPaywallButtonTapped(sender)
            }
        }
    }

    @IBAction func restoreButtonTapped(_ sender: UIButton) {
        MonetixService.shared.restorePurchases()
    }

    private func unlockPremiumFeatures() {
        // Your premium unlock logic
        print("✅ Premium features unlocked!")
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - MonetixAnalyticsDelegate

extension OnboardingViewController: MonetixAnalyticsDelegate {
    func onPaywallOpen(paywallName: String, isABTest: Bool, abTestName: String?) {
        print("📊 Paywall opened: \(paywallName)")
        // Send to your analytics (Firebase, Mixpanel, etc.)
    }

    func onPaywallClose() {
        print("📊 Paywall closed")
    }

    func onPurchaseSuccess(
        purchaseTransactionId: String,
        paywallName: String,
        productId: String,
        isABTest: Bool,
        abTestName: String?
    ) {
        print("📊 Purchase successful: \(productId)")
        unlockPremiumFeatures()
    }

    func onPurchaseFailed(
        paywallName: String,
        isABTest: Bool,
        abTestName: String?,
        productCode: String,
        errorCode: String,
        errorDetail: String
    ) {
        print("📊 Purchase failed: \(errorDetail)")
    }

    func onRestoreSuccess() {
        print("📊 Restore successful")
        unlockPremiumFeatures()
    }

    func isNotVisiblePaywall(errorDetail: String, paywallName: String) {
        print("📊 Paywall error: \(errorDetail)")
    }
}
```

## 🎯 Adapty'den Farklılıklar

| Özellik | Adapty | MonetixSDK |
|---------|--------|------------|
| **Backend** | Adapty sunucuları | Kendi backend'iniz |
| **API Stili** | Aynı | Aynı (uyumlu) |
| **Aktivasyon** | `Adapty.activate()` | `Monetix.shared.activate()` |
| **Profile** | `Adapty.getProfile()` | `Monetix.shared.getProfile()` |
| **Paywall** | `Adapty.getPaywall()` | `Monetix.shared.getPaywall()` |
| **Purchase** | `Adapty.makePurchase()` | `Monetix.shared.makePurchase()` |
| **Restore** | `Adapty.restorePurchases()` | `Monetix.shared.restorePurchases()` |
| **Access Level** | `profile.accessLevels["premium"]` | `profile.isPremium` |
| **Transaction ID** | `subscription.vendorOriginalTransactionId` | Aynı |
| **Delegate** | `AdaptyPaywallControllerDelegate` | `MonetixPaywallControllerDelegate` |
| **Log Handler** | `Adapty.setLogHandler()` | `Monetix.shared.setLogHandler()` |

## ✅ Migration Checklist

- [ ] `AdaptyService` sınıfını `MonetixService` ile değiştir
- [ ] `Adapty.activate()` → `Monetix.shared.activate()`
- [ ] `Adapty.getProfile()` → `Monetix.shared.getProfile()`
- [ ] `Adapty.getPaywall()` → `Monetix.shared.getPaywall()`
- [ ] `Adapty.makePurchase()` → `Monetix.shared.makePurchase()`
- [ ] `AdaptyPaywallControllerDelegate` → `MonetixPaywallControllerDelegate`
- [ ] `profile.accessLevels["premium"]?.isActive` → `profile.isPremium`
- [ ] Backend URL'ini konfigürasyonda ayarla
- [ ] API key'i backend'den al ve kullan

## 🎉 Tamamlandı!

Artık MonetixSDK kullanıma hazır! Adapty ile aynı kullanım deneyimini yaşayacaksınız, ama kendi backend'inizle tam kontrol sizde. 🚀
