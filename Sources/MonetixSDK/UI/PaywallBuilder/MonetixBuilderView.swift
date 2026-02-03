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
            backgroundView
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

    @ViewBuilder
    private var backgroundView: some View {
        if let bg = viewConfiguration?.background, bg.type == "image", let urlString = bg.url, let url = URL(string: urlString) {
            // Background image with optional overlay
            ZStack {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_):
                        Color(hex: viewConfiguration?.backgroundColor ?? "#FFFFFF")
                    case .empty:
                        Color(hex: viewConfiguration?.backgroundColor ?? "#FFFFFF")
                    @unknown default:
                        Color(hex: viewConfiguration?.backgroundColor ?? "#FFFFFF")
                    }
                }

                // Overlay
                if let overlayColor = bg.overlayColor {
                    Color(hex: overlayColor)
                        .opacity(bg.overlayOpacity ?? 0.4)
                }
            }
        } else if let bg = viewConfiguration?.background, bg.type == "gradient", let colors = bg.gradientColors, colors.count >= 2 {
            // Gradient background
            let (startPoint, endPoint) = gradientPoints(for: bg.gradientDirection)
            LinearGradient(
                colors: colors.map { Color(hex: $0) },
                startPoint: startPoint,
                endPoint: endPoint
            )
        } else {
            // Solid color background
            Color(hex: viewConfiguration?.backgroundColor ?? "#FFFFFF")
        }
    }

    private var contentStack: some View {
        VStack(spacing: 0) {
            ForEach(viewConfiguration?.elements ?? [], id: \.id) { element in
                elementView(for: element)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var closeButtonOverlay: some View {
        let closeElement: MonetixPaywallElement? = viewConfiguration?.elements.first(where: { $0.type == .closeButton })

        return Group {
            if let closeElement = closeElement {
                let position: String = closeElement.position ?? "topRight"
                let delay: TimeInterval = closeElement.showDelay ?? 0
                let buttonColor: Color = Color(hex: closeElement.style?.color ?? "#000000")
                let sfSymbol: String = closeElement.systemImage ?? "xmark"

                VStack {
                    HStack {
                        if position == "topRight" {
                            Spacer()
                        }

                        Button(action: onClose) {
                            Image(systemName: sfSymbol)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(buttonColor)
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
    }

    private var loadingOverlay: some View {
        Group {
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay(ProgressView())
            }
        }
    }

    // MARK: - Element Rendering

    private func elementView(for element: MonetixPaywallElement) -> AnyView {
        switch element.type {
        case .text:
            return AnyView(textView(element))
        case .image:
            return AnyView(imageView(element))
        case .button:
            return AnyView(buttonView(element))
        case .productList:
            return AnyView(productListView(element))
        case .purchaseButton:
            return AnyView(purchaseButtonView(element))
        case .featureList:
            return AnyView(featureListView(element))
        case .spacer:
            return AnyView(spacerView(element))
        case .divider:
            return AnyView(dividerView(element))
        case .container:
            return AnyView(containerView(element))
        case .stack:
            return AnyView(stackView(element))
        case .restoreButton:
            return AnyView(restoreButtonView(element))
        case .badge:
            return AnyView(badgeView(element))
        case .closeButton:
            return AnyView(EmptyView()) // Rendered as overlay
        case .timer, .video:
            return AnyView(EmptyView()) // TODO: Implement
        }
    }

    // MARK: - Text Element

    private func textView(_ element: MonetixPaywallElement) -> some View {
        let fontSize: CGFloat = CGFloat(element.style?.fontSize ?? 16)
        let fontWeightValue: Font.Weight = fontWeight(element.style?.fontWeight)
        let textColor: Color = Color(hex: element.style?.color ?? "#000000")
        let align: TextAlignment = textAlignment(element.style?.alignment)
        let frameAlign: Alignment = frameAlignment(element.style?.alignment)
        let paddingInsets: EdgeInsets = edgeInsets(element.style?.padding)
        let marginInsets: EdgeInsets = edgeInsets(element.style?.margin)

        return Text(element.text ?? "")
            .font(.system(size: fontSize, weight: fontWeightValue))
            .foregroundColor(textColor)
            .multilineTextAlignment(align)
            .frame(maxWidth: .infinity, alignment: frameAlign)
            .padding(paddingInsets)
            .padding(marginInsets)
    }

    // MARK: - Image Element

    private func imageView(_ element: MonetixPaywallElement) -> some View {
        let cornerRadius: CGFloat = element.style?.cornerRadius ?? 0
        let widthVal: CGFloat? = widthValue(element.style?.width)
        let heightVal: CGFloat? = heightValue(element.style?.height)
        let paddingInsets: EdgeInsets = edgeInsets(element.style?.padding)
        let marginInsets: EdgeInsets = edgeInsets(element.style?.margin)
        let mode: ContentMode = contentMode(element.contentMode)

        return Group {
            if let urlString = element.url, let url = URL(string: urlString) {
                HStack {
                    Spacer()
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: mode)
                        case .failure:
                            Color.gray.opacity(0.3)
                        case .empty:
                            ProgressView()
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: widthVal, height: heightVal)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    Spacer()
                }
                .padding(paddingInsets)
                .padding(marginInsets)
            }
        }
    }
    
    private func widthValue(_ dimension: MonetixDimension?) -> CGFloat? {
        guard let dimension = dimension else { return nil }
        switch dimension {
        case .fixed(let value): return value
        case .full, .auto: return nil
        }
    }

    // MARK: - Button Element

    private func buttonView(_ element: MonetixPaywallElement) -> some View {
        let fontSize: CGFloat = CGFloat(element.style?.fontSize ?? 16)
        let fontWeightValue: Font.Weight = fontWeight(element.style?.fontWeight)
        let textColor: Color = Color(hex: element.style?.textColor ?? element.style?.color ?? "#FFFFFF")
        let bgColor: Color = Color(hex: element.style?.backgroundColor ?? "#007AFF")
        let heightVal: CGFloat = heightValue(element.style?.height) ?? 50
        let cornerRadius: CGFloat = element.style?.cornerRadius ?? 12
        let paddingInsets: EdgeInsets = edgeInsets(element.style?.padding)
        let marginInsets: EdgeInsets = edgeInsets(element.style?.margin)
        let buttonText: String = element.text ?? ""
        let action: String? = element.action
        let actionUrl: String? = element.actionUrl

        return Button(action: {
            handleAction(action, url: actionUrl)
        }) {
            Text(buttonText)
                .font(.system(size: fontSize, weight: fontWeightValue))
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: heightVal)
                .background(bgColor)
                .cornerRadius(cornerRadius)
        }
        .padding(paddingInsets)
        .padding(marginInsets)
    }

    // MARK: - Product List Element

    private func productListView(_ element: MonetixPaywallElement) -> some View {
        let layout: String = element.layout ?? "vertical"
        let showBadge: Bool = element.showBadge ?? true
        let showDescription: Bool = element.showDescription ?? true
        let showPrice: Bool = element.showPrice ?? true
        let paddingInsets: EdgeInsets = edgeInsets(element.style?.padding)
        let marginInsets: EdgeInsets = edgeInsets(element.style?.margin)

        return Group {
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
        .padding(paddingInsets)
        .padding(marginInsets)
    }

    private func productCard(_ product: MonetixProduct, showBadge: Bool, showDescription: Bool, showPrice: Bool) -> some View {
        let isSelected: Bool = selectedProduct?.id == product.id
        let bgColor: Color = isSelected ? Color.blue.opacity(0.1) : Color(UIColor.secondarySystemBackground)
        let strokeColor: Color = isSelected ? Color.blue : Color.gray.opacity(0.3)
        let strokeWidth: CGFloat = isSelected ? 2 : 1
        let priceText: String = product.localizedPrice ?? ""

        return Button(action: {
            selectedProduct = product
        }) {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.localizedTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                if showDescription && !product.localizedDescription.isEmpty {
                    Text(product.localizedDescription)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                if showPrice {
                    Text(priceText)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(bgColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(strokeColor, lineWidth: strokeWidth)
            )
        }
    }

    // MARK: - Purchase Button Element

    private func purchaseButtonView(_ element: MonetixPaywallElement) -> some View {
        let buttonText: String = element.text ?? "Continue"
        let fontSize: CGFloat = CGFloat(element.style?.fontSize ?? 17)
        let fontWeightStr: String = element.style?.fontWeight ?? "semibold"
        let fontWeightValue: Font.Weight = fontWeight(fontWeightStr)
        let textColor: Color = Color(hex: element.style?.textColor ?? "#FFFFFF")
        let bgColor: Color = Color(hex: element.style?.backgroundColor ?? "#007AFF")
        let heightVal: CGFloat = heightValue(element.style?.height) ?? 50
        let cornerRadius: CGFloat = element.style?.cornerRadius ?? 12
        let paddingInsets: EdgeInsets = edgeInsets(element.style?.padding)
        let marginInsets: EdgeInsets = edgeInsets(element.style?.margin)
        let productId: String? = element.productId

        return Button(action: {
            Task {
                await performPurchase(productId: productId)
            }
        }) {
            Text(buttonText)
                .font(.system(size: fontSize, weight: fontWeightValue))
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: heightVal)
                .background(bgColor)
                .cornerRadius(cornerRadius)
        }
        .padding(paddingInsets)
        .padding(marginInsets)
    }

    // MARK: - Feature List Element

    private func featureListView(_ element: MonetixPaywallElement) -> some View {
        let defaultIconColor: String = element.iconColor ?? "#34C759"
        let features: [MonetixFeatureItem] = element.features ?? []
        let paddingInsets: EdgeInsets = edgeInsets(element.style?.padding)
        let marginInsets: EdgeInsets = edgeInsets(element.style?.margin)
        let textColor: Color = Color(hex: element.style?.color ?? "#000000")
        let fontSize: CGFloat = CGFloat(element.style?.fontSize ?? 15)

        return VStack(spacing: 16) {
            ForEach(features, id: \.text) { feature in
                let iconColorStr: String = feature.iconColor ?? defaultIconColor
                HStack(spacing: 12) {
                    // Use SF Symbol if systemImage is provided, otherwise use emoji/text icon
                    if let sfSymbol = feature.systemImage {
                        Image(systemName: sfSymbol)
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: iconColorStr))
                            .frame(width: 24)
                    } else {
                        Text(systemIcon(for: feature.icon))
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: iconColorStr))
                            .frame(width: 24)
                    }

                    Text(feature.text)
                        .font(.system(size: fontSize))
                        .foregroundColor(textColor)

                    Spacer()
                }
            }
        }
        .padding(paddingInsets)
        .padding(marginInsets)
    }

    // MARK: - Spacer Element

    private func spacerView(_ element: MonetixPaywallElement) -> some View {
        let size: CGFloat? = element.size
        let isFlexible: Bool = element.flexible == true

        return Group {
            if let size = size {
                Spacer().frame(height: size)
            } else if isFlexible {
                Spacer()
            } else {
                Spacer().frame(height: 16)
            }
        }
    }

    // MARK: - Divider Element

    private func dividerView(_ element: MonetixPaywallElement) -> some View {
        let fillColor: Color = Color(hex: element.style?.backgroundColor ?? element.style?.color ?? "#E5E5E5")
        let thickness: CGFloat = element.thickness ?? 1
        let paddingInsets: EdgeInsets = edgeInsets(element.style?.padding)
        let marginInsets: EdgeInsets = edgeInsets(element.style?.margin)

        return Rectangle()
            .fill(fillColor)
            .frame(height: thickness)
            .padding(paddingInsets)
            .padding(marginInsets)
    }

    // MARK: - Container Element

    private func containerView(_ element: MonetixPaywallElement) -> some View {
        let children: [MonetixPaywallElement] = element.children ?? []
        let paddingInsets: EdgeInsets = edgeInsets(element.style?.padding)
        let marginInsets: EdgeInsets = edgeInsets(element.style?.margin)
        let bgColor: Color = Color(hex: element.style?.backgroundColor ?? "clear")
        let cornerRadius: CGFloat = element.style?.cornerRadius ?? 0

        return VStack(spacing: 0) {
            ForEach(children, id: \.id) { child in
                elementView(for: child)
            }
        }
        .padding(paddingInsets)
        .background(bgColor)
        .cornerRadius(cornerRadius)
        .padding(marginInsets)
    }

    // MARK: - Stack Element

    private func stackView(_ element: MonetixPaywallElement) -> some View {
        let axis: String = element.axis ?? "vertical"
        let spacing: CGFloat = element.spacing ?? 0
        let children: [MonetixPaywallElement] = element.children ?? []
        let paddingInsets: EdgeInsets = edgeInsets(element.style?.padding)
        let marginInsets: EdgeInsets = edgeInsets(element.style?.margin)

        return Group {
            if axis == "horizontal" {
                HStack(spacing: spacing) {
                    ForEach(children, id: \.id) { child in
                        elementView(for: child)
                    }
                }
            } else {
                VStack(spacing: spacing) {
                    ForEach(children, id: \.id) { child in
                        elementView(for: child)
                    }
                }
            }
        }
        .padding(paddingInsets)
        .padding(marginInsets)
    }

    // MARK: - Restore Button Element

    private func restoreButtonView(_ element: MonetixPaywallElement) -> some View {
        let buttonText: String = element.text ?? "Restore Purchases"
        let fontSize: CGFloat = CGFloat(element.style?.fontSize ?? 14)
        let textColor: Color = Color(hex: element.style?.color ?? element.style?.textColor ?? "#8E8E93")
        let paddingInsets: EdgeInsets = edgeInsets(element.style?.padding)
        let marginInsets: EdgeInsets = edgeInsets(element.style?.margin)

        return Button(action: {
            Task {
                await performRestore()
            }
        }) {
            Text(buttonText)
                .font(.system(size: fontSize))
                .foregroundColor(textColor)
        }
        .padding(paddingInsets)
        .padding(marginInsets)
    }

    // MARK: - Badge Element

    private func badgeView(_ element: MonetixPaywallElement) -> some View {
        let badgeText: String = element.badgeText ?? element.text ?? ""
        let textColor: Color = Color(hex: element.style?.textColor ?? element.style?.color ?? "#FFFFFF")
        let bgColor: Color = Color(hex: element.style?.backgroundColor ?? "#007AFF")
        let cornerRadius: CGFloat = element.style?.cornerRadius ?? 4
        let paddingInsets: EdgeInsets = edgeInsets(element.style?.padding)
        let marginInsets: EdgeInsets = edgeInsets(element.style?.margin)

        return Text(badgeText)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(bgColor)
            .cornerRadius(cornerRadius)
            .padding(paddingInsets)
            .padding(marginInsets)
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

    private func gradientPoints(for direction: String?) -> (UnitPoint, UnitPoint) {
        switch direction?.lowercased() {
        case "horizontal":
            return (.leading, .trailing)
        case "diagonal":
            return (.topLeading, .bottomTrailing)
        case "diagonal-reverse", "diagonalreverse":
            return (.topTrailing, .bottomLeading)
        case "vertical":
            return (.top, .bottom)
        default:
            return (.top, .bottom)
        }
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
    @ViewBuilder
    func monetixBuilderPaywall(
        isPresented: Binding<Bool>,
        paywall: MonetixPaywall?,
        products: [MonetixProduct],
        onPurchase: @escaping (MonetixProduct) async throws -> MonetixPurchaseResult,
        onRestore: @escaping () async throws -> MonetixProfile,
        onDismiss: @escaping () -> Void
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
