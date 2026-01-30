//
//  SimpleExample.swift
//  MonetixSDK Example
//
//  A minimal example showing how to use MonetixSDK
//

import SwiftUI
import MonetixSDK

// MARK: - App Entry Point

@main
struct MonetixExampleApp: App {
    init() {
        configureMonetixSDK()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    private func configureMonetixSDK() {
        Task {
            let configuration = MonetixConfiguration
                .builder(withAPIKey: "your-api-key-here")
                .with(customerUserId: getUserId())
                .with(environment: .sandbox)
                .with(logLevel: .debug)
                .build()

            do {
                try await Monetix.shared.activate(with: configuration)
                print("✅ MonetixSDK activated successfully!")
            } catch {
                print("❌ MonetixSDK activation failed: \(error)")
            }
        }

        // Optional: Set log handler
        Monetix.shared.setLogHandler { level, message, function in
            print("[\(level.rawValue)] \(function): \(message)")
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

// MARK: - Content View

struct ContentView: View {
    @StateObject private var viewModel = SubscriptionViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Premium Status
                premiumStatusSection

                // Actions
                actionsSection

                Spacer()
            }
            .padding()
            .navigationTitle("MonetixSDK Example")
        }
        .task {
            await viewModel.checkPremiumStatus()
        }
    }

    private var premiumStatusSection: some View {
        VStack(spacing: 10) {
            Image(systemName: viewModel.isPremium ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(viewModel.isPremium ? .green : .gray)

            Text(viewModel.isPremium ? "Premium Active" : "Free User")
                .font(.title2)
                .bold()

            if viewModel.isLoading {
                ProgressView()
            }
        }
        .padding()
    }

    private var actionsSection: some View {
        VStack(spacing: 15) {
            Button("Check Premium Status") {
                Task {
                    await viewModel.checkPremiumStatus()
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Show Paywall") {
                viewModel.showPaywall = true
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isPremium)

            Button("Restore Purchases") {
                Task {
                    await viewModel.restorePurchases()
                }
            }
            .buttonStyle(.bordered)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .sheet(isPresented: $viewModel.showPaywall) {
            PaywallExampleView()
        }
    }
}

// MARK: - ViewModel

@MainActor
class SubscriptionViewModel: ObservableObject {
    @Published var isPremium: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showPaywall: Bool = false

    func checkPremiumStatus() async {
        isLoading = true
        errorMessage = nil

        do {
            let profile = try await Monetix.shared.getProfile()
            isPremium = profile.isPremium
            print("✅ Premium status: \(isPremium)")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to check premium: \(error)")
        }

        isLoading = false
    }

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

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
            print("❌ Restore failed: \(error)")
        }

        isLoading = false
    }
}

// MARK: - Paywall View

struct PaywallExampleView: View {
    @Environment(\.dismiss) var dismiss
    @State private var paywall: MonetixPaywall?
    @State private var products: [MonetixProduct] = []
    @State private var isLoading = true
    @State private var isPurchasing = false

    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    ProgressView("Loading...")
                } else if let paywall = paywall {
                    paywallContent(paywall)
                } else {
                    Text("Failed to load paywall")
                }
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadPaywall()
        }
    }

    @ViewBuilder
    private func paywallContent(_ paywall: MonetixPaywall) -> some View {
        VStack(spacing: 20) {
            Text("Unlock Premium")
                .font(.largeTitle)
                .bold()

            Text("Get access to all premium features")
                .foregroundColor(.secondary)

            Spacer()

            // Products
            ForEach(products, id: \.id) { product in
                ProductRow(product: product) {
                    purchaseProduct(product)
                }
            }

            Spacer()

            Button("Restore Purchases") {
                restorePurchases()
            }
            .foregroundColor(.blue)

            if isPurchasing {
                ProgressView()
            }
        }
        .padding()
    }

    private func loadPaywall() async {
        isLoading = true

        do {
            let fetchedPaywall = try await Monetix.shared.getPaywall(placementId: "onboarding")
            let fetchedProducts = try await Monetix.shared.getPaywallProducts(paywall: fetchedPaywall)

            paywall = fetchedPaywall
            products = fetchedProducts

            Monetix.shared.logShowPaywall(fetchedPaywall)
        } catch {
            print("Failed to load paywall: \(error)")
        }

        isLoading = false
    }

    private func purchaseProduct(_ product: MonetixProduct) {
        Task {
            isPurchasing = true

            do {
                let result = try await Monetix.shared.makePurchase(product: product)

                if !result.isPurchaseCancelled, let profile = result.profile, profile.isPremium {
                    dismiss()
                }
            } catch {
                print("Purchase failed: \(error)")
            }

            isPurchasing = false
        }
    }

    private func restorePurchases() {
        Task {
            isPurchasing = true

            do {
                let profile = try await Monetix.shared.restorePurchases()
                if profile.isPremium {
                    dismiss()
                }
            } catch {
                print("Restore failed: \(error)")
            }

            isPurchasing = false
        }
    }
}

// MARK: - Product Row

struct ProductRow: View {
    let product: MonetixProduct
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(product.name)
                        .font(.headline)

                    if let period = product.subscriptionPeriod {
                        Text("\(period.value) \(period.unit.rawValue)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(product.localizedPrice ?? "\(product.price)")
                        .font(.title3)
                        .bold()

                    Text(product.currencyCode)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
