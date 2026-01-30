# 🚀 iOS Projene MonetixSDK Entegrasyonu

Bu guide, MonetixSDK'yı iOS projenize adım adım nasıl entegre edeceğinizi gösterir.

---

## 📋 Gereksinimler

- iOS 15.0 veya üzeri
- Xcode 15.0 veya üzeri
- Swift 5.9 veya üzeri
- Active Apple Developer Account
- Monetix Backend API Key

---

## 🎯 Adım 1: Swift Package Manager ile Kurulum

### Xcode'da Paket Ekle

1. Xcode'da projenizi açın
2. **File → Add Package Dependencies** seçin
3. Sağ üstteki arama kutusuna MonetixSDK repository URL'ini girin:
   ```
   https://github.com/your-org/MonetixSDK
   ```
4. **Dependency Rule:** "Up to Next Major Version" seçin (1.0.0)
5. **Add to Project:** Projenizi seçin
6. **Add Package** butonuna tıklayın

### Package.swift ile Kurulum (SPM Projeleri için)

```swift
dependencies: [
    .package(url: "https://github.com/your-org/MonetixSDK", from: "1.0.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: ["MonetixSDK"]
    )
]
```

---

## 🔧 Adım 2: Info.plist Konfigürasyonu

### App Store Connect API için Bundle ID

`Info.plist` dosyanıza bundle identifier'ınızı ekleyin (zaten olmalı):

```xml
<key>CFBundleIdentifier</key>
<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
```

### StoreKit Configuration (Testing için)

Xcode'da local StoreKit testing için:

1. **File → New → File**
2. **StoreKit Configuration File** seçin
3. İsim verin (örn: `Products.storekit`)
4. Test ürünlerinizi ekleyin

---

## 💳 Adım 3: App Store Connect Ayarları

### 1. In-App Purchase Ürünleri Oluştur

1. [App Store Connect](https://appstoreconnect.apple.com) giriş yapın
2. **Apps → Your App → In-App Purchases** seçin
3. Yeni ürün ekle (+)
4. **Subscription** tipini seçin
5. Product ID girin (örn: `com.yourapp.premium.monthly`)
6. Fiyat ve süre bilgilerini girin
7. Save

### 2. Subscription Group Oluştur

1. **Subscriptions** altında bir subscription group oluşturun
2. Ürünlerinizi bu gruba ekleyin

---

## 📱 Adım 4: AppDelegate Entegrasyonu

### SwiftUI App

```swift
import SwiftUI
import MonetixSDK

@main
struct YourApp: App {
    @StateObject private var subscriptionManager = SubscriptionManager()

    init() {
        configureMonetix()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(subscriptionManager)
        }
    }

    private func configureMonetix() {
        Task {
            let configuration = MonetixConfiguration
                .builder(withAPIKey: "your-monetix-api-key-here")
                .with(customerUserId: getUserId()) // Unique user ID
                .with(environment: .production)
                .with(observerMode: false)
                .with(logLevel: .debug)
                .build()

            do {
                try await Monetix.shared.activate(with: configuration)
                print("✅ Monetix activated")
            } catch {
                print("❌ Monetix activation failed: \(error)")
            }
        }

        // Optional: Set log handler
        Monetix.shared.setLogHandler { level, message, function in
            print("[\(level.rawValue.uppercased())] \(function): \(message)")
        }
    }

    private func getUserId() -> String {
        // Your user ID logic (Firebase UID, UUID, etc.)
        if let userId = UserDefaults.standard.string(forKey: "userId") {
            return userId
        }

        let newUserId = UUID().uuidString
        UserDefaults.standard.set(newUserId, forKey: "userId")
        return newUserId
    }
}
```

### UIKit AppDelegate

```swift
import UIKit
import MonetixSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        configureMonetix()

        return true
    }

    private func configureMonetix() {
        Task {
            let configuration = MonetixConfiguration
                .builder(withAPIKey: "your-monetix-api-key-here")
                .with(customerUserId: getUserId())
                .with(environment: .production)
                .with(observerMode: false)
                .with(logLevel: .debug)
                .build()

            do {
                try await Monetix.shared.activate(with: configuration)
                print("✅ Monetix activated")
            } catch {
                print("❌ Monetix activation failed: \(error)")
            }
        }

        Monetix.shared.setLogHandler { level, message, function in
            print("[\(level.rawValue.uppercased())] \(function): \(message)")
        }
    }

    private func getUserId() -> String {
        if let userId = UserDefaults.standard.string(forKey: "userId") {
            return userId
        }

        let newUserId = UUID().uuidString
        UserDefaults.standard.set(newUserId, forKey: "userId")
        return newUserId
    }
}
```

---

## 🎨 Adım 5: Subscription Manager Oluştur

Observable pattern ile subscription durumunu yönetin:

```swift
import Foundation
import MonetixSDK

@MainActor
class SubscriptionManager: ObservableObject {
    @Published var isPremium: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func checkSubscription() async {
        isLoading = true

        do {
            let profile = try await Monetix.shared.getProfile()
            isPremium = profile.isPremium
        } catch {
            errorMessage = error.localizedDescription
            isPremium = false
        }

        isLoading = false
    }

    func restorePurchases() async {
        isLoading = true

        do {
            let profile = try await Monetix.shared.restorePurchases()
            isPremium = profile.isPremium

            if isPremium {
                print("✅ Restore successful!")
            } else {
                errorMessage = "No active subscription found"
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
```

---

## 🎪 Adım 6: Paywall Görünümü

### SwiftUI Paywall View

```swift
import SwiftUI
import MonetixSDK

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var paywall: MonetixPaywall?
    @State private var products: [MonetixProduct] = []
    @State private var isLoading = false

    let placementId: String

    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
            } else if let paywall = paywall {
                VStack(spacing: 20) {
                    // Header
                    Text("Unlock Premium")
                        .font(.largeTitle)
                        .bold()

                    Text("Get unlimited access to all features")
                        .foregroundColor(.secondary)

                    // Products
                    ForEach(products, id: \.id) { product in
                        ProductCard(product: product) {
                            purchaseProduct(product)
                        }
                    }

                    // Restore button
                    Button("Restore Purchases") {
                        restorePurchases()
                    }
                    .foregroundColor(.blue)

                    // Close button
                    Button("Maybe Later") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .task {
            await loadPaywall()
        }
    }

    private func loadPaywall() async {
        isLoading = true

        do {
            let fetchedPaywall = try await Monetix.shared.getPaywall(placementId: placementId)
            let fetchedProducts = try await Monetix.shared.getPaywallProducts(paywall: fetchedPaywall)

            paywall = fetchedPaywall
            products = fetchedProducts

            // Log show event
            Monetix.shared.logShowPaywall(fetchedPaywall)
        } catch {
            print("Error loading paywall: \(error)")
        }

        isLoading = false
    }

    private func purchaseProduct(_ product: MonetixProduct) {
        Task {
            isLoading = true

            do {
                let result = try await Monetix.shared.makePurchase(product: product)

                if !result.isPurchaseCancelled {
                    await subscriptionManager.checkSubscription()
                    dismiss()
                }
            } catch {
                print("Purchase failed: \(error)")
            }

            isLoading = false
        }
    }

    private func restorePurchases() {
        Task {
            await subscriptionManager.restorePurchases()
            if subscriptionManager.isPremium {
                dismiss()
            }
        }
    }
}

struct ProductCard: View {
    let product: MonetixProduct
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading) {
                    Text(product.name)
                        .font(.headline)

                    if let period = product.subscriptionPeriod {
                        Text("\(period.value) \(period.unit.rawValue)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Text(product.localizedPrice ?? "\(product.price) \(product.currencyCode)")
                    .font(.title3)
                    .bold()
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
```

### UIKit Paywall ViewController

```swift
import UIKit
import MonetixSDK

class PaywallViewController: UIViewController {
    private var paywall: MonetixPaywall?
    private var products: [MonetixProduct] = []

    private let placementId: String
    private let tableView = UITableView()
    private let loadingView = UIActivityIndicatorView(style: .large)

    init(placementId: String) {
        self.placementId = placementId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        loadPaywall()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProductCell.self, forCellReuseIdentifier: "ProductCell")
        view.addSubview(tableView)

        // Loading view
        view.addSubview(loadingView)

        // Layout
        tableView.translatesAutoresizingMaskIntoConstraints = false
        loadingView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func loadPaywall() {
        loadingView.startAnimating()

        Task {
            do {
                let fetchedPaywall = try await Monetix.shared.getPaywall(placementId: placementId)
                let fetchedProducts = try await Monetix.shared.getPaywallProducts(paywall: fetchedPaywall)

                await MainActor.run {
                    self.paywall = fetchedPaywall
                    self.products = fetchedProducts
                    self.tableView.reloadData()
                    self.loadingView.stopAnimating()
                }

                Monetix.shared.logShowPaywall(fetchedPaywall)
            } catch {
                print("Error loading paywall: \(error)")
                await MainActor.run {
                    self.loadingView.stopAnimating()
                }
            }
        }
    }

    private func purchaseProduct(_ product: MonetixProduct) {
        loadingView.startAnimating()

        Task {
            do {
                let result = try await Monetix.shared.makePurchase(product: product)

                if !result.isPurchaseCancelled {
                    await MainActor.run {
                        self.dismiss(animated: true)
                    }
                }
            } catch {
                print("Purchase failed: \(error)")
            }

            await MainActor.run {
                self.loadingView.stopAnimating()
            }
        }
    }
}

extension PaywallViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell", for: indexPath) as! ProductCell
        cell.configure(with: products[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        purchaseProduct(products[indexPath.row])
    }
}
```

---

## 🎭 Adım 7: Premium Kontrol

```swift
// Premium kontrolü
func checkPremium() async {
    do {
        let isPremium = try await Monetix.shared.checkAccess()

        if isPremium {
            // Unlock premium features
            unlockPremiumFeatures()
        } else {
            // Show paywall
            showPaywall()
        }
    } catch {
        print("Error checking premium: \(error)")
    }
}

// Premium özellikleri unlock et
private func unlockPremiumFeatures() {
    // Your premium features
    print("✅ Premium features unlocked!")
}
```

---

## 📊 Adım 8: Analytics Entegrasyonu (Opsiyonel)

```swift
class AnalyticsManager: MonetixAnalyticsDelegate {
    static let shared = AnalyticsManager()

    func onPaywallOpen(paywallName: String, isABTest: Bool, abTestName: String?) {
        // Firebase, Mixpanel, vs.
        Analytics.logEvent("paywall_open", parameters: [
            "paywall_name": paywallName,
            "is_ab_test": isABTest
        ])
    }

    func onPaywallClose() {
        Analytics.logEvent("paywall_close")
    }

    func onPurchaseSuccess(
        purchaseTransactionId: String,
        paywallName: String,
        productId: String,
        isABTest: Bool,
        abTestName: String?
    ) {
        Analytics.logEvent("purchase_success", parameters: [
            "transaction_id": purchaseTransactionId,
            "product_id": productId
        ])
    }

    func onPurchaseFailed(
        paywallName: String,
        isABTest: Bool,
        abTestName: String?,
        productCode: String,
        errorCode: String,
        errorDetail: String
    ) {
        Analytics.logEvent("purchase_failed", parameters: [
            "product_code": productCode,
            "error_code": errorCode
        ])
    }

    func onRestoreSuccess() {
        Analytics.logEvent("restore_success")
    }

    func isNotVisiblePaywall(errorDetail: String, paywallName: String) {
        Analytics.logEvent("paywall_error", parameters: [
            "error": errorDetail
        ])
    }
}
```

---

## ✅ Adım 9: Test Etme

### Sandbox Testing

1. Xcode'da **Product → Scheme → Edit Scheme**
2. **Run → Options → StoreKit Configuration** seçin
3. Kendi `.storekit` dosyanızı seçin
4. Uygulamayı run edin

### TestFlight Testing

1. Archive ve TestFlight'a yükleyin
2. Sandbox test kullanıcısı oluşturun (App Store Connect)
3. TestFlight uygulamasında test edin

---

## 🎉 Tamamlandı!

MonetixSDK başarıyla entegre edildi!

### Kontrol Listesi:
- [x] SDK kurulumu (SPM)
- [x] Info.plist konfigürasyonu
- [x] In-App Purchase ürünleri oluşturuldu
- [x] AppDelegate'de SDK aktivasyonu
- [x] Subscription manager
- [x] Paywall görünümü
- [x] Premium kontrol
- [x] Analytics (opsiyonel)
- [x] Test

### Sonraki Adımlar:
1. Backend URL'ini production'a ayarlayın
2. API key'i backend'den alın
3. App Store Connect'te ürünleri production'a alın
4. App Review'e gönderin

---

## 🆘 Sorun mu yaşıyorsunuz?

- [README.md](README.md) - Genel kullanım
- [USAGE_EXAMPLE.md](USAGE_EXAMPLE.md) - Detaylı örnekler
- [BACKEND_INTEGRATION.md](BACKEND_INTEGRATION.md) - Backend API
- [GitHub Issues](https://github.com/your-org/MonetixSDK/issues)

---

Made with ❤️ by Monetix Team
