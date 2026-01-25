# ⚡ MonetixSDK - Quick Start (5 Dakikada Başla)

## 🎯 1. SDK'yı Ekle (30 saniye)

Xcode'da **File → Add Package Dependencies**:
```
https://github.com/your-org/MonetixSDK
```

## 🔧 2. Backend URL'i Ayarla (1 dakika)

`Sources/MonetixSDK/Core/MonetixConfiguration.swift` dosyasını aç:

```swift
var baseURL: String {
    switch self {
    case .production:
        return "https://YOUR-BACKEND-URL.com/api"  // 👈 BURAYA BACKEND URL'İNİZİ YAZIN.
    case .sandbox:
        return "https://YOUR-SANDBOX-URL.com/api"
    }
}
```

## 🚀 3. SDK'yı Aktive Et (1 dakika)

**SwiftUI:**
```swift
import MonetixSDK

@main
struct MyApp: App {
    init() {
        Task {
            let config = MonetixConfiguration
                .builder(withAPIKey: "YOUR-API-KEY")  // 👈 API KEY'İNİZİ BURAYA
                .with(customerUserId: "user-123")
                .with(environment: .production)
                .build()

            try await Monetix.shared.activate(with: config)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**UIKit:**
```swift
import MonetixSDK

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, ...) -> Bool {
        Task {
            let config = MonetixConfiguration
                .builder(withAPIKey: "YOUR-API-KEY")
                .with(customerUserId: "user-123")
                .build()

            try await Monetix.shared.activate(with: config)
        }
        return true
    }
}
```

## 💳 4. Premium Kontrol Et (30 saniye)

```swift
let isPremium = try await Monetix.shared.checkAccess()

if isPremium {
    // Premium kullanıcı
} else {
    // Paywall göster
}
```

## 🎪 5. Paywall Göster (2 dakika)

```swift
// Paywall al
let paywall = try await Monetix.shared.getPaywall(placementId: "onboarding")

// Ürünleri al
let products = try await Monetix.shared.getPaywallProducts(paywall: paywall)

// SwiftUI'da göster
.sheet(isPresented: $showPaywall) {
    PaywallView(paywall: paywall, products: products)
}

// UIKit'te göster
let vc = PaywallViewController(paywall: paywall, products: products)
present(vc, animated: true)
```

## 💰 6. Satın Alma Yap (30 saniye)

```swift
let result = try await Monetix.shared.makePurchase(product: selectedProduct)

if let profile = result.profile, profile.isPremium {
    // Başarılı! Premium aç
}
```

## 🔄 7. Restore Purchases (30 saniye)

```swift
let profile = try await Monetix.shared.restorePurchases()

if profile.isPremium {
    // Premium aktif
}
```

---

## ✅ Hepsi Bu Kadar!

5 dakikada MonetixSDK entegrasyonu tamamlandı! 🎉

### 📚 Daha Fazlası İçin:

- [README.md](README.md) - Detaylı dokümantasyon
- [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md) - Adım adım entegrasyon
- [USAGE_EXAMPLE.md](USAGE_EXAMPLE.md) - Adapty migration
- [CONFIGURATION.md](CONFIGURATION.md) - Konfigürasyon seçenekleri
- [BACKEND_INTEGRATION.md](BACKEND_INTEGRATION.md) - Backend API

---

## 🆘 Sorun mu Var?

**"Invalid API Key" hatası?**
→ Backend URL ve API key'i kontrol edin

**"Not Activated" hatası?**
→ `Monetix.shared.activate()` çağrıldığından emin olun

**Build hatası?**
→ iOS 15.0+ ve Swift 5.9+ gereklidir

---

Made with ❤️ by Monetix Team
