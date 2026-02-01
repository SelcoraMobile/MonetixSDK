//
//  MonetixBuilderView.swift
//  MonetixSDK
//
//  Paywall Builder - Server-Driven UI View (SwiftUI)
//

#if canImport(UIKit)
import SwiftUI
import UIKit

/// SwiftUI view for rendering Paywall Builder paywalls (server-driven UI)
/// Use this when `paywall.usesPaywallBuilder` is true
@available(iOS 15.0, *)
public struct MonetixBuilderView: View {
    let paywall: MonetixPaywall
    let products: [MonetixProduct]

    let onPurchase: (MonetixProduct) async throws -> MonetixPurchaseResult
    let onRestore: () async throws -> MonetixProfile
    let onClose: () -> Void

    @State private var selectedProduct: MonetixProduct?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showCloseButton = false

    private var viewConfiguration: MonetixViewConfiguration? {
        paywall.viewConfiguration
    }

    public init(
        paywall: MonetixPaywall,
        products: [MonetixProduct],
        onPurchase: @escaping (MonetixProduct) async throws -> MonetixPurchaseResult,
        onRestore: @escaping () async throws -> MonetixProfile,
        onClose: @escaping () -> Void
    ) {
        self.paywall = paywall
        self.products = products
        self.onPurchase = onPurchase
        self.onRestore = onRestore
        self.onClose = onClose
        self._selectedProduct = State(initialValue: products.first)
    }

    public var body: some View {
        ZStack {
            // Background
            Color(hex: viewConfiguration?.backgroundColor ?? "#FFFFFF")
                .ignoresSafeArea()

            // Content
            if viewConfiguration?.scrollEnabled ?? true {
                ScrollView {
                    contentStack
                }
            } else {
                contentStack
            }

            // Close button overlay (if specified in elements)
            closeButtonOverlay
        }
        .overlay(loadingOverlay)
    }

    private var contentStack: some View {
        VStack(spacing: 0) {
            ForEach(viewConfiguration?.elements ?? [], id: \.id) { element in
                elementView(for: element)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var closeButtonOverlay: some View {
        if let closeElement = viewConfiguration?.elements.first(where: { $0.type == .closeButton }) {
            let position = closeElement.position ?? "topRight"
            let delay = closeElement.showDelay ?? 0

            VStack {
                HStack {
                    if position == "topRight" {
                        Spacer()
                    }

                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: closeElement.style?.color ?? "#000000"))
                            .frame(width: 44, height: 44)
                    }
                    .opacity(showCloseButton ? 1 : 0)

                    if position == "topLeft" {
                        Spacer()
                    }
                }
                Spacer()
            }
            .padding(8)
            .onAppear {
                if delay > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        withAnimation {
                            showCloseButton = true
                        }
                    }
                } else {
                    showCloseButton = true
                }
            }
        }
    }

    @ViewBuilder
    private var loadingOverlay: some View {
        if isLoading {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .overlay(ProgressView())
        }
    }

    // MARK: - Element Rendering

    @ViewBuilder
    private func elementView(for element: MonetixPaywallElement) -> some View {
        switch element.type {
        case .text:
            textView(element)
        case .image:
            imageView(element)
        case .button:
            buttonView(element)
        case .productList:
            productListView(element)
        case .purchaseButton:
            purchaseButtonView(element)
        case .featureList:
            featureListView(element)
        case .spacer:
            spacerView(element)
        case .divider:
            dividerView(element)
        case .container:
            containerView(element)
        case .stack:
            stackView(element)
        case .restoreButton:
            restoreButtonView(element)
        case .badge:
            badgeView(element)
        case .closeButton:
            EmptyView() // Rendered as overlay
        case .timer, .video:
            EmptyView() // TODO: Implement
        }
    }

    // MARK: - Text Element

    @ViewBuilder
    private func textView(_ element: MonetixPaywallElement) -> some View {
        Text(element.text ?? "")
            .font(.system(
                size: CGFloat(element.style?.fontSize ?? 16),
                weight: fontWeight(element.style?.fontWeight)
            ))
            .foregroundColor(Color(hex: element.style?.color ?? "#000000"))
            .multilineTextAlignment(textAlignment(element.style?.alignment))
            .frame(maxWidth: .infinity, alignment: frameAlignment(element.style?.alignment))
            .padding(edgeInsets(element.style?.padding))
            .padding(edgeInsets(element.style?.margin))
    }

    // MARK: - Image Element

    @ViewBuilder
    private func imageView(_ element: MonetixPaywallElement) -> some View {
        if let urlString = element.url, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: contentMode(element.contentMode))
                case .failure:
                    Color.gray.opacity(0.3)
                case .empty:
                    ProgressView()
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: heightValue(element.style?.height))
            .clipShape(RoundedRectangle(cornerRadius: element.style?.cornerRadius ?? 0))
            .padding(edgeInsets(element.style?.padding))
            .padding(edgeInsets(element.style?.margin))
        }
    }

    // MARK: - Button Element

    @ViewBuilder
    private func buttonView(_ element: MonetixPaywallElement) -> some View {
        Button(action: {
            handleAction(element.action, url: element.actionUrl)
        }) {
            Text(element.text ?? "")
                .font(.system(
                    size: CGFloat(element.style?.fontSize ?? 16),
                    weight: fontWeight(element.style?.fontWeight)
                ))
                .foregroundColor(Color(hex: element.style?.textColor ?? element.style?.color ?? "#FFFFFF"))
                .frame(maxWidth: .infinity)
                .frame(height: heightValue(element.style?.height) ?? 50)
                .background(Color(hex: element.style?.backgroundColor ?? "#007AFF"))
                .cornerRadius(element.style?.cornerRadius ?? 12)
        }
        .padding(edgeInsets(element.style?.padding))
        .padding(edgeInsets(element.style?.margin))
    }

    // MARK: - Product List Element

    @ViewBuilder
    private func productListView(_ element: MonetixPaywallElement) -> some View {
        let layout = element.layout ?? "vertical"
        let showBadge = element.showBadge ?? true
        let showDescription = element.showDescription ?? true
        let showPrice = element.showPrice ?? true

        Group {
            if layout == "horizontal" {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(products, id: \.id) { product in
                            productCard(product, showBadge: showBadge, showDescription: showDescription, showPrice: showPrice)
                                .frame(width: 160)
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(products, id: \.id) { product in
                        productCard(product, showBadge: showBadge, showDescription: showDescription, showPrice: showPrice)
                    }
                }
            }
        }
        .padding(edgeInsets(element.style?.padding))
        .padding(edgeInsets(element.style?.margin))
    }

    @ViewBuilder
    private func productCard(_ product: MonetixProduct, showBadge: Bool, showDescription: Bool, showPrice: Bool) -> some View {
        let isSelected = selectedProduct?.id == product.id

        Button(action: {
            selectedProduct = product
        }) {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.localizedTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                if showDescription, !product.localizedDescription.isEmpty {
                    Text(product.localizedDescription)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                if showPrice {
                    Text(product.localizedPrice ?? "")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
    }

    // MARK: - Purchase Button Element

    @ViewBuilder
    private func purchaseButtonView(_ element: MonetixPaywallElement) -> some View {
        Button(action: {
            Task {
                await performPurchase(productId: element.productId)
            }
        }) {
            Text(element.text ?? "Continue")
                .font(.system(
                    size: CGFloat(element.style?.fontSize ?? 17),
                    weight: fontWeight(element.style?.fontWeight ?? "semibold")
                ))
                .foregroundColor(Color(hex: element.style?.textColor ?? "#FFFFFF"))
                .frame(maxWidth: .infinity)
                .frame(height: heightValue(element.style?.height) ?? 50)
                .background(Color(hex: element.style?.backgroundColor ?? "#007AFF"))
                .cornerRadius(element.style?.cornerRadius ?? 12)
        }
        .padding(edgeInsets(element.style?.padding))
        .padding(edgeInsets(element.style?.margin))
    }

    // MARK: - Feature List Element

    @ViewBuilder
    private func featureListView(_ element: MonetixPaywallElement) -> some View {
        let iconColor = element.iconColor ?? "#34C759"

        VStack(spacing: 12) {
            ForEach(element.features ?? [], id: \.text) { feature in
                HStack(spacing: 12) {
                    Text(systemIcon(for: feature.icon))
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: feature.iconColor ?? iconColor))
                        .frame(width: 24)

                    Text(feature.text)
                        .font(.system(size: 15))
                        .foregroundColor(.primary)

                    Spacer()
                }
            }
        }
        .padding(edgeInsets(element.style?.padding))
        .padding(edgeInsets(element.style?.margin))
    }

    // MARK: - Spacer Element

    @ViewBuilder
    private func spacerView(_ element: MonetixPaywallElement) -> some View {
        if let size = element.size {
            Spacer().frame(height: size)
        } else if element.flexible == true {
            Spacer()
        } else {
            Spacer().frame(height: 16)
        }
    }

    // MARK: - Divider Element

    @ViewBuilder
    private func dividerView(_ element: MonetixPaywallElement) -> some View {
        Rectangle()
            .fill(Color(hex: element.style?.backgroundColor ?? element.style?.color ?? "#E5E5E5"))
            .frame(height: element.thickness ?? 1)
            .padding(edgeInsets(element.style?.padding))
            .padding(edgeInsets(element.style?.margin))
    }

    // MARK: - Container Element

    @ViewBuilder
    private func containerView(_ element: MonetixPaywallElement) -> some View {
        VStack(spacing: 0) {
            ForEach(element.children ?? [], id: \.id) { child in
                elementView(for: child)
            }
        }
        .padding(edgeInsets(element.style?.padding))
        .background(Color(hex: element.style?.backgroundColor ?? "clear"))
        .cornerRadius(element.style?.cornerRadius ?? 0)
        .padding(edgeInsets(element.style?.margin))
    }

    // MARK: - Stack Element

    @ViewBuilder
    private func stackView(_ element: MonetixPaywallElement) -> some View {
        let axis = element.axis ?? "vertical"
        let spacing = element.spacing ?? 0

        Group {
            if axis == "horizontal" {
                HStack(spacing: spacing) {
                    ForEach(element.children ?? [], id: \.id) { child in
                        elementView(for: child)
                    }
                }
            } else {
                VStack(spacing: spacing) {
                    ForEach(element.children ?? [], id: \.id) { child in
                        elementView(for: child)
                    }
                }
            }
        }
        .padding(edgeInsets(element.style?.padding))
        .padding(edgeInsets(element.style?.margin))
    }

    // MARK: - Restore Button Element

    @ViewBuilder
    private func restoreButtonView(_ element: MonetixPaywallElement) -> some View {
        Button(action: {
            Task {
                await performRestore()
            }
        }) {
            Text(element.text ?? "Restore Purchases")
                .font(.system(size: CGFloat(element.style?.fontSize ?? 14)))
                .foregroundColor(Color(hex: element.style?.color ?? element.style?.textColor ?? "#8E8E93"))
        }
        .padding(edgeInsets(element.style?.padding))
        .padding(edgeInsets(element.style?.margin))
    }

    // MARK: - Badge Element

    @ViewBuilder
    private func badgeView(_ element: MonetixPaywallElement) -> some View {
        Text(element.badgeText ?? element.text ?? "")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(Color(hex: element.style?.textColor ?? element.style?.color ?? "#FFFFFF"))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(hex: element.style?.backgroundColor ?? "#007AFF"))
            .cornerRadius(element.style?.cornerRadius ?? 4)
            .padding(edgeInsets(element.style?.padding))
            .padding(edgeInsets(element.style?.margin))
    }

    // MARK: - Helpers

    private func handleAction(_ action: String?, url: String?) {
        switch action {
        case "close":
            onClose()
        case "restore":
            Task { await performRestore() }
        case "link":
            if let urlString = url, let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        default:
            break
        }
    }

    private func performPurchase(productId: String?) async {
        var productToPurchase: MonetixProduct?

        if let productId = productId {
            productToPurchase = products.first { $0.id == productId || $0.vendorProductId == productId }
        } else {
            productToPurchase = selectedProduct ?? products.first
        }

        guard let product = productToPurchase else { return }

        isLoading = true
        do {
            _ = try await onPurchase(product)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    private func performRestore() async {
        isLoading = true
        do {
            _ = try await onRestore()
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    private func fontWeight(_ string: String?) -> Font.Weight {
        switch string?.lowercased() {
        case "bold": return .bold
        case "semibold": return .semibold
        case "medium": return .medium
        case "light": return .light
        case "thin": return .thin
        default: return .regular
        }
    }

    private func textAlignment(_ string: String?) -> TextAlignment {
        switch string?.lowercased() {
        case "left": return .leading
        case "right": return .trailing
        case "center": return .center
        default: return .leading
        }
    }

    private func frameAlignment(_ string: String?) -> Alignment {
        switch string?.lowercased() {
        case "left": return .leading
        case "right": return .trailing
        case "center": return .center
        default: return .leading
        }
    }

    private func contentMode(_ string: String?) -> ContentMode {
        switch string?.lowercased() {
        case "fill": return .fill
        default: return .fit
        }
    }

    private func heightValue(_ dimension: MonetixDimension?) -> CGFloat? {
        guard let dimension = dimension else { return nil }
        switch dimension {
        case .fixed(let value): return value
        case .full, .auto: return nil
        }
    }

    private func edgeInsets(_ insets: MonetixEdgeInsets?) -> EdgeInsets {
        guard let insets = insets else { return EdgeInsets() }
        return EdgeInsets(top: insets.top, leading: insets.left, bottom: insets.bottom, trailing: insets.right)
    }

    private func systemIcon(for iconName: String) -> String {
        let iconMap: [String: String] = [
            "check": "checkmark.circle.fill",
            "star": "star.fill",
            "heart": "heart.fill"
        ]
        // Return emoji or the icon name itself
        if iconMap[iconName.lowercased()] != nil {
            return "✓"
        }
        return iconName
    }
}

// MARK: - Color Extension

@available(iOS 15.0, *)
extension Color {
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        // Handle "clear" color
        if hexSanitized.lowercased() == "clear" {
            self = .clear
            return
        }

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r, g, b, a: Double
        switch hexSanitized.count {
        case 6:
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
            a = 1.0
        case 8:
            r = Double((rgb & 0xFF000000) >> 24) / 255.0
            g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            a = Double(rgb & 0x000000FF) / 255.0
        default:
            r = 0
            g = 0
            b = 0
            a = 1.0
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - View Extensions

@available(iOS 15.0, *)
public extension View {
    /// Present a Paywall Builder paywall as a sheet
    func monetixBuilderPaywall(
        isPresented: Binding<Bool>,
        paywall: MonetixPaywall?,
        products: [MonetixProduct],
        onPurchase: @escaping (MonetixProduct) async throws -> MonetixPurchaseResult = { try await Monetix.shared.makePurchase(product: $0) },
        onRestore: @escaping () async throws -> MonetixProfile = { try await Monetix.shared.restorePurchases() },
        onDismiss: @escaping () -> Void = {}
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            if let paywall = paywall, paywall.usesPaywallBuilder {
                MonetixBuilderView(
                    paywall: paywall,
                    products: products,
                    onPurchase: onPurchase,
                    onRestore: onRestore,
                    onClose: {
                        isPresented.wrappedValue = false
                        onDismiss()
                    }
                )
            }
        }
    }
}
#endif
