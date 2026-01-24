# ⚙️ MonetixSDK Configuration Guide

## Backend URL Konfigürasyonu

MonetixSDK'yı kullanmadan önce backend URL'inizi ayarlamanız gerekiyor.

### 1. Dosyayı Düzenleyin

`Sources/MonetixSDK/Core/MonetixConfiguration.swift` dosyasını açın:

```swift
public enum Environment {
    case production
    case sandbox

    var baseURL: String {
        switch self {
        case .production:
            return "https://your-backend-url.com/api"  // 👈 BURAYA KENDİ URL'NİZİ YAZIN
        case .sandbox:
            return "https://sandbox-backend-url.com/api"  // 👈 SANDBOX URL'NİZ
        }
    }
}
```

### 2. Örnek Konfigürasyon

```swift
public enum Environment {
    case production
    case sandbox

    var baseURL: String {
        switch self {
        case .production:
            return "https://api.myapp.com/v1"  // Production backend
        case .sandbox:
            return "https://sandbox-api.myapp.com/v1"  // Test backend
        }
    }
}
```

---

## API Key Alma

### Backend'den API Key Oluşturma

1. Monetix backend admin paneline giriş yapın
2. **Settings → API Keys** menüsüne gidin
3. **Create New API Key** butonuna tıklayın
4. Platform seçin: **iOS**
5. Environment seçin: **Production** veya **Sandbox**
6. API key'i kopyalayın

### API Key'i Kullanma

```swift
let configuration = MonetixConfiguration
    .builder(withAPIKey: "your-api-key-here")  // 👈 API KEY'İNİZİ BURAYA YAPIŞTIRIN
    .with(customerUserId: "user-123")
    .with(environment: .production)  // .production veya .sandbox
    .build()
```

---

## Environment Seçimi

### Production Environment

Canlı uygulamanız için:

```swift
let configuration = MonetixConfiguration
    .builder(withAPIKey: "prod_xxxxxxxxxxxxx")
    .with(environment: .production)  // 👈 Production backend
    .build()
```

### Sandbox Environment

Test ve development için:

```swift
let configuration = MonetixConfiguration
    .builder(withAPIKey: "sandbox_xxxxxxxxxxxxx")
    .with(environment: .sandbox)  // 👈 Sandbox backend
    .build()
```

---

## User ID Stratejileri

### 1. UUID (Basit)

```swift
func getUserId() -> String {
    if let userId = UserDefaults.standard.string(forKey: "userId") {
        return userId
    }

    let newUserId = UUID().uuidString
    UserDefaults.standard.set(newUserId, forKey: "userId")
    return newUserId
}

let configuration = MonetixConfiguration
    .builder(withAPIKey: "your-api-key")
    .with(customerUserId: getUserId())
    .build()
```

### 2. Firebase User ID (Önerilen)

```swift
import FirebaseAuth

func getUserId() -> String? {
    return Auth.auth().currentUser?.uid
}

if let userId = getUserId() {
    let configuration = MonetixConfiguration
        .builder(withAPIKey: "your-api-key")
        .with(customerUserId: userId)
        .build()
} else {
    // User not logged in, show login screen
}
```

### 3. Custom Backend User ID

```swift
func getUserId() -> String? {
    // Your own authentication system
    return MyAuthService.shared.currentUser?.id
}
```

### 4. Anonymous User (İlk açılışta)

```swift
// İlk açılışta anonymous ID oluştur
let anonymousId = UUID().uuidString
UserDefaults.standard.set(anonymousId, forKey: "anonymousUserId")

// Kullanıcı login olduğunda gerçek ID'ye geç
if let realUserId = MyAuth.currentUser?.id {
    // Migrate anonymous to real user
    await migrateUser(from: anonymousId, to: realUserId)
}
```

---

## Debug Modu

### Log Level Seçimi

```swift
let configuration = MonetixConfiguration
    .builder(withAPIKey: "your-api-key")
    .with(logLevel: .debug)  // .error, .warn, .info, .debug, .verbose
    .build()
```

**Log Levels:**
- `.error` - Sadece hatalar
- `.warn` - Uyarılar ve hatalar
- `.info` - Genel bilgiler (önerilen)
- `.debug` - Detaylı debug bilgileri
- `.verbose` - Her şey (sadece development)

### Custom Log Handler

```swift
Monetix.shared.setLogHandler { level, message, function in
    switch level {
    case .error:
        print("🔴 ERROR [\(function)]: \(message)")
        // Send to Crashlytics
        Crashlytics.crashlytics().log("Monetix Error: \(message)")

    case .warn:
        print("⚠️ WARNING [\(function)]: \(message)")

    case .info:
        print("ℹ️ INFO: \(message)")

    case .debug, .verbose:
        print("🔍 DEBUG [\(function)]: \(message)")
    }
}
```

---

## Observer Mode

### Ne zaman kullanılır?

- Satın almaları başka bir SDK yönetiyorsa (örn: RevenueCat ile birlikte)
- Sadece analytics için kullanıyorsanız
- Backend entegrasyonu tamamlanmadıysa (test aşaması)

```swift
let configuration = MonetixConfiguration
    .builder(withAPIKey: "your-api-key")
    .with(observerMode: true)  // 👈 Purchases backend'e gönderilmez
    .build()
```

⚠️ **Uyarı:** Observer mode'da purchases backend'e **bildirilmez**. Sadece izleme yapar.

---

## Tam Örnek Konfigürasyon

### Production-Ready Setup

```swift
import MonetixSDK
import FirebaseAuth

class MonetixManager {
    static let shared = MonetixManager()

    private init() {}

    func configure() {
        #if DEBUG
        configureDebug()
        #else
        configureProduction()
        #endif
    }

    private func configureDebug() {
        guard let userId = getCurrentUserId() else { return }

        let configuration = MonetixConfiguration
            .builder(withAPIKey: "sandbox_key_here")
            .with(customerUserId: userId)
            .with(environment: .sandbox)
            .with(logLevel: .debug)
            .with(observerMode: false)
            .build()

        activateSDK(with: configuration)
    }

    private func configureProduction() {
        guard let userId = getCurrentUserId() else { return }

        let configuration = MonetixConfiguration
            .builder(withAPIKey: "prod_key_here")
            .with(customerUserId: userId)
            .with(environment: .production)
            .with(logLevel: .info)
            .with(observerMode: false)
            .build()

        activateSDK(with: configuration)
    }

    private func activateSDK(with configuration: MonetixConfiguration) {
        Task {
            do {
                try await Monetix.shared.activate(with: configuration)
                print("✅ Monetix SDK activated")

                // Set log handler
                Monetix.shared.setLogHandler { level, message, function in
                    self.handleLog(level: level, message: message, function: function)
                }
            } catch {
                print("❌ Monetix activation failed: \(error)")
            }
        }
    }

    private func getCurrentUserId() -> String? {
        // Try Firebase first
        if let firebaseId = Auth.auth().currentUser?.uid {
            return firebaseId
        }

        // Fallback to anonymous
        if let anonymousId = UserDefaults.standard.string(forKey: "anonymousUserId") {
            return anonymousId
        }

        // Create new anonymous
        let newAnonymousId = "anon_\(UUID().uuidString)"
        UserDefaults.standard.set(newAnonymousId, forKey: "anonymousUserId")
        return newAnonymousId
    }

    private func handleLog(level: MonetixLogLevel, message: String, function: String) {
        #if DEBUG
        print("[\(level.rawValue.uppercased())] \(function): \(message)")
        #else
        if level == .error || level == .warn {
            // Send to analytics/crashlytics
            Analytics.logEvent("monetix_\(level.rawValue)", parameters: [
                "message": message,
                "function": function
            ])
        }
        #endif
    }
}

// AppDelegate veya App struct'ta:
MonetixManager.shared.configure()
```

---

## Environment Variables (Advanced)

### Xcode Build Configuration

1. **Targets → Your App → Build Settings**
2. **User-Defined** altında yeni variable ekle:
   - `MONETIX_API_KEY_PROD`
   - `MONETIX_API_KEY_SANDBOX`

3. Info.plist'e ekle:
```xml
<key>MonetixAPIKey</key>
<string>$(MONETIX_API_KEY_PROD)</string>
```

4. Kod'da kullan:
```swift
let apiKey = Bundle.main.object(forInfoDictionaryKey: "MonetixAPIKey") as? String ?? ""

let configuration = MonetixConfiguration
    .builder(withAPIKey: apiKey)
    .build()
```

---

## Security Best Practices

### ✅ Yapılması Gerekenler

- API key'i environment variable olarak sakla
- Production ve Sandbox key'leri ayır
- User ID'leri hash'le (opsiyonel)
- HTTPS kullan (zorunlu)
- Log level'i production'da `.info` veya daha düşük yap

### ❌ Yapılmaması Gerekenler

- API key'i hardcode etme
- API key'i Git'e commit etme
- Debug logları production'da aktif bırakma
- Observer mode'u production'da kullanma (gerekmedikçe)

---

## Troubleshooting

### "Invalid API Key" Hatası

```swift
// Backend URL'i kontrol edin
print(configuration.environment.baseURL)

// API key formatını kontrol edin
print(configuration.apiKey.hasPrefix("prod_") || configuration.apiKey.hasPrefix("sandbox_"))
```

### "Not Activated" Hatası

```swift
// activate() çağrılmış mı kontrol edin
Task {
    try await Monetix.shared.activate(with: configuration)
    // Şimdi diğer API'leri kullanabilirsiniz
    let profile = try await Monetix.shared.getProfile()
}
```

### Network Hatası

```swift
// Backend URL'i ping edin
curl https://your-backend-url.com/api/health

// SSL sertifikası geçerli mi?
// Firewall kuralları var mı?
```

---

## Sonraki Adımlar

1. ✅ Backend URL'i ayarla
2. ✅ API key al ve konfigüre et
3. ✅ User ID stratejisi belirle
4. ✅ Log handler ayarla
5. ✅ Environment seçimini yap
6. 📖 [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md) - iOS projesine entegrasyon
7. 📖 [USAGE_EXAMPLE.md](USAGE_EXAMPLE.md) - Kullanım örnekleri

---

Made with ❤️ by Monetix Team
