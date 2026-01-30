# 🔗 Backend Integration Guide

Bu döküman, MonetixSDK'nın backend ile nasıl entegre olduğunu ve backend'inizin hangi endpoint'leri sağlaması gerektiğini açıklar.

## 📡 Backend Endpoint'leri

MonetixSDK, aşağıdaki endpoint'lere HTTP istekleri yapar. Tüm istekler `X-Api-Key` header'ı ile authentication gerektirir.

### Base URL Konfigürasyonu

```swift
// MonetixConfiguration.swift içinde güncelleyin:
public enum Environment {
    case production
    case sandbox

    var baseURL: String {
        switch self {
        case .production:
            return "https://your-backend-url.com/api"  // Buraya kendi backend URL'nizi yazın
        case .sandbox:
            return "https://sandbox-backend-url.com/api"
        }
    }
}
```

---

## 🔐 Authentication

Her API isteği `X-Api-Key` header'ı içermelidir:

```
Headers:
  X-Api-Key: your-api-key-here
  Content-Type: application/json
```

---

## 📋 Endpoint Listesi

### 1. **Get User Profile**

Kullanıcı profilini ve abonelik bilgilerini getirir.

```
GET /users/{userId}/profile
```

**Response:**
```json
{
  "user_id": "user-123",
  "is_premium": true,
  "subscription": {
    "id": "sub-456",
    "product_id": "premium_monthly",
    "status": "active",
    "expires_at": "2026-02-03T12:00:00Z",
    "started_at": "2026-01-03T12:00:00Z",
    "is_trial": false,
    "is_grace_period": false,
    "vendor_transaction_id": "2000000123456789",
    "vendor_original_transaction_id": "1000000123456789",
    "auto_renew_status": true
  },
  "custom_attributes": {
    "custom_key": "custom_value"
  }
}
```

---

### 2. **Check Premium Access**

Kullanıcının premium erişimini kontrol eder (daha hızlı).

```
GET /access/check/{userId}
```

**Response:**
```json
{
  "is_premium": true,
  "is_active": true
}
```

---

### 3. **Get Paywall**

Placement ID'ye göre paywall bilgilerini getirir.

```
GET /paywalls/{placementId}?locale=en
```

**Query Parameters:**
- `locale` (optional): Language code (örn: "en", "tr")

**Response:**
```json
{
  "id": "paywall-789",
  "placement_id": "onboarding",
  "name": "Onboarding Paywall v1",
  "ab_test_name": "Onboarding A/B Test",
  "variant_id": "variant-1",
  "products": [
    {
      "id": "product-1",
      "vendor_product_id": "com.app.premium.monthly",
      "name": "Premium Monthly",
      "product_type": "subscription",
      "price": 9.99,
      "currency_code": "USD",
      "localized_price": "$9.99",
      "subscription_period": {
        "unit": "month",
        "value": 1
      }
    }
  ],
  "remote_config": {
    "data": {
      "title": "Unlock Premium Features",
      "subtitle": "Get unlimited access",
      "features": ["Feature 1", "Feature 2"]
    }
  }
}
```

---

### 4. **Get Paywall Products**

Bir paywall için ürün listesini getirir.

```
GET /paywalls/{paywallId}/products
```

**Response:**
```json
[
  {
    "id": "product-1",
    "vendor_product_id": "com.app.premium.monthly",
    "name": "Premium Monthly",
    "product_type": "subscription",
    "price": 9.99,
    "currency_code": "USD",
    "localized_price": "$9.99",
    "subscription_period": {
      "unit": "month",
      "value": 1
    }
  }
]
```

---

### 5. **Report Purchase**

Yeni satın alma işlemini backend'e bildirir.

```
POST /purchases
```

**Request Body:**
```json
{
  "user_id": "user-123",
  "product_id": "com.app.premium.monthly",
  "transaction_id": "2000000123456789",
  "original_transaction_id": "1000000123456789",
  "receipt": "base64-encoded-receipt-data"
}
```

**Response:**
```json
{
  "success": true
}
```

---

### 6. **Restore Purchases**

Kullanıcının satın almalarını restore eder.

```
POST /purchases/restore
```

**Request Body:**
```json
{
  "user_id": "user-123",
  "receipt": "base64-encoded-receipt-data"
}
```

**Response:** (Same as Get User Profile)
```json
{
  "user_id": "user-123",
  "is_premium": true,
  "subscription": { ... }
}
```

---

### 7. **Send Analytics Event**

Kullanıcı event'lerini gönderir (opsiyonel).

```
POST /events
```

**Request Body:**
```json
{
  "user_id": "user-123",
  "event_type": "purchase_success",
  "properties": {
    "transaction_id": "2000000123456789",
    "product_id": "com.app.premium.monthly",
    "paywall_name": "onboarding"
  },
  "timestamp": "2026-01-03T12:00:00Z"
}
```

**Response:**
```json
{
  "success": true
}
```

---

### 8. **Send SDK Logs** (Opsiyonel)

SDK loglarını backend'e gönderir.

```
POST /logs
```

**Request Body:**
```json
{
  "description": "Monetix SDK activated successfully",
  "level": "info",
  "function": "activate(with:)",
  "timestamp": "2026-01-03T12:00:00Z"
}
```

**Response:**
```json
{
  "success": true
}
```

---

## 🔄 Subscription Status Values

Backend'iniz aşağıdaki subscription status değerlerini desteklemelidir:

```swift
enum SubscriptionStatus: String {
    case active          // Aktif abonelik
    case expired         // Süresi dolmuş
    case cancelled       // İptal edilmiş ama hala aktif
    case refunded        // İade edilmiş
    case grace_period    // Ödeme hatası, grace period'da
    case billing_retry   // Ödeme yeniden deneniyor
}
```

---

## 🛠️ Backend Implementation Checklist

### Gerekli Endpoint'ler:
- [ ] `GET /users/{userId}/profile`
- [ ] `GET /access/check/{userId}`
- [ ] `GET /paywalls/{placementId}`
- [ ] `GET /paywalls/{paywallId}/products`
- [ ] `POST /purchases`
- [ ] `POST /purchases/restore`

### Opsiyonel Endpoint'ler:
- [ ] `POST /events` (Analytics için)
- [ ] `POST /logs` (SDK logging için)

### Security:
- [ ] API Key authentication (`X-Api-Key` header)
- [ ] Rate limiting
- [ ] HTTPS zorunlu
- [ ] Input validation

### Apple Integration:
- [ ] StoreKit 2 receipt verification
- [ ] Apple Server Notifications V2 webhook handler
- [ ] Transaction JWS signature validation

---

## 🧪 Test Endpoint'leri

Development sırasında test için basit mock endpoint'ler:

### Mock User Profile
```json
{
  "user_id": "test-user",
  "is_premium": true,
  "subscription": {
    "id": "test-sub",
    "product_id": "com.app.premium.monthly",
    "status": "active",
    "expires_at": "2026-12-31T23:59:59Z",
    "started_at": "2026-01-01T00:00:00Z",
    "is_trial": false,
    "is_grace_period": false,
    "vendor_transaction_id": "test-transaction",
    "vendor_original_transaction_id": "test-original",
    "auto_renew_status": true
  }
}
```

### Mock Paywall
```json
{
  "id": "test-paywall",
  "placement_id": "onboarding",
  "name": "Test Paywall",
  "ab_test_name": null,
  "variant_id": null,
  "products": [
    {
      "id": "prod-1",
      "vendor_product_id": "com.app.premium.monthly",
      "name": "Premium Monthly",
      "product_type": "subscription",
      "price": 9.99,
      "currency_code": "USD"
    }
  ]
}
```

---

## 📊 Example Backend Implementation (Node.js/Express)

```javascript
const express = require('express');
const app = express();

// Middleware
app.use(express.json());

// API Key authentication
app.use((req, res, next) => {
  const apiKey = req.headers['x-api-key'];
  if (!apiKey || !isValidApiKey(apiKey)) {
    return res.status(401).json({ error: 'Invalid API key' });
  }
  next();
});

// Get user profile
app.get('/api/users/:userId/profile', async (req, res) => {
  const { userId } = req.params;

  // Your logic to fetch user profile
  const profile = await getUserProfile(userId);

  res.json(profile);
});

// Check access
app.get('/api/access/check/:userId', async (req, res) => {
  const { userId } = req.params;

  const isPremium = await checkUserPremium(userId);

  res.json({
    is_premium: isPremium,
    is_active: isPremium
  });
});

// Get paywall
app.get('/api/paywalls/:placementId', async (req, res) => {
  const { placementId } = req.params;
  const { locale } = req.query;

  const paywall = await getPaywall(placementId, locale);

  res.json(paywall);
});

// Report purchase
app.post('/api/purchases', async (req, res) => {
  const { user_id, product_id, transaction_id, receipt } = req.body;

  // Verify receipt with Apple
  const verified = await verifyAppleReceipt(receipt);

  if (verified) {
    // Save purchase to database
    await savePurchase({
      userId: user_id,
      productId: product_id,
      transactionId: transaction_id
    });

    res.json({ success: true });
  } else {
    res.status(400).json({ error: 'Invalid receipt' });
  }
});

app.listen(3000, () => {
  console.log('Backend running on port 3000');
});
```

---

## 🔗 İlgili Dökümanlar

- [Monetix Backend Repository](https://github.com/your-org/Monetix)
- [Apple Server Notifications V2](https://developer.apple.com/documentation/appstoreservernotifications)
- [StoreKit 2 Receipt Validation](https://developer.apple.com/documentation/storekit/in-app_purchase/original_api_for_in-app_purchase/validating_receipts_with_the_app_store)

---

Made with ❤️ by Monetix Team
