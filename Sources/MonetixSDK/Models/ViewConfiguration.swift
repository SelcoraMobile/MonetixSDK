//
//  ViewConfiguration.swift
//  MonetixSDK
//
//  Paywall Builder - Server-Driven UI Models
//

import Foundation

// MARK: - View Configuration

/// View configuration for Paywall Builder (server-driven UI)
public struct MonetixViewConfiguration: Codable, Sendable {
    /// Configuration version
    public let version: String

    /// Background color (hex string)
    public let backgroundColor: String

    /// Background configuration (image, gradient, etc.)
    public let background: MonetixBackgroundConfig?

    /// Whether to respect safe area at top
    public let safeAreaTop: Bool

    /// Whether to respect safe area at bottom
    public let safeAreaBottom: Bool

    /// Whether scrolling is enabled
    public let scrollEnabled: Bool

    /// Paywall elements
    public let elements: [MonetixPaywallElement]

    enum CodingKeys: String, CodingKey {
        case version
        case backgroundColor
        case background
        case safeAreaTop
        case safeAreaBottom
        case scrollEnabled
        case elements
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(String.self, forKey: .version) ?? "1.0"
        backgroundColor = try container.decodeIfPresent(String.self, forKey: .backgroundColor) ?? "#FFFFFF"
        background = try container.decodeIfPresent(MonetixBackgroundConfig.self, forKey: .background)
        safeAreaTop = try container.decodeIfPresent(Bool.self, forKey: .safeAreaTop) ?? true
        safeAreaBottom = try container.decodeIfPresent(Bool.self, forKey: .safeAreaBottom) ?? true
        scrollEnabled = try container.decodeIfPresent(Bool.self, forKey: .scrollEnabled) ?? true
        elements = try container.decodeIfPresent([MonetixPaywallElement].self, forKey: .elements) ?? []
    }

    public init(
        version: String = "1.0",
        backgroundColor: String = "#FFFFFF",
        background: MonetixBackgroundConfig? = nil,
        safeAreaTop: Bool = true,
        safeAreaBottom: Bool = true,
        scrollEnabled: Bool = true,
        elements: [MonetixPaywallElement] = []
    ) {
        self.version = version
        self.backgroundColor = backgroundColor
        self.background = background
        self.safeAreaTop = safeAreaTop
        self.safeAreaBottom = safeAreaBottom
        self.scrollEnabled = scrollEnabled
        self.elements = elements
    }
}

// MARK: - Element Type

/// Types of elements supported in Paywall Builder
public enum MonetixPaywallElementType: String, Codable, Sendable {
    case text
    case image
    case button
    case productList
    case purchaseButton
    case featureList
    case spacer
    case divider
    case container
    case closeButton
    case restoreButton
    case video
    case timer
    case badge
    case stack
}

// MARK: - Element Style

/// Style properties for paywall elements
public struct MonetixElementStyle: Codable, Sendable {
    public let fontSize: Int?
    public let fontWeight: String?
    public let color: String?
    public let backgroundColor: String?
    public let textColor: String?
    public let alignment: String?
    public let cornerRadius: CGFloat?
    public let padding: MonetixEdgeInsets?
    public let margin: MonetixEdgeInsets?
    public let width: MonetixDimension?
    public let height: MonetixDimension?
    public let opacity: CGFloat?
    public let borderWidth: CGFloat?
    public let borderColor: String?
    public let lineHeight: CGFloat?
    public let letterSpacing: CGFloat?
    public let shadowColor: String?
    public let shadowRadius: CGFloat?
    public let shadowOffset: MonetixOffset?

    public init(
        fontSize: Int? = nil,
        fontWeight: String? = nil,
        color: String? = nil,
        backgroundColor: String? = nil,
        textColor: String? = nil,
        alignment: String? = nil,
        cornerRadius: CGFloat? = nil,
        padding: MonetixEdgeInsets? = nil,
        margin: MonetixEdgeInsets? = nil,
        width: MonetixDimension? = nil,
        height: MonetixDimension? = nil,
        opacity: CGFloat? = nil,
        borderWidth: CGFloat? = nil,
        borderColor: String? = nil,
        lineHeight: CGFloat? = nil,
        letterSpacing: CGFloat? = nil,
        shadowColor: String? = nil,
        shadowRadius: CGFloat? = nil,
        shadowOffset: MonetixOffset? = nil
    ) {
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.color = color
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.alignment = alignment
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.margin = margin
        self.width = width
        self.height = height
        self.opacity = opacity
        self.borderWidth = borderWidth
        self.borderColor = borderColor
        self.lineHeight = lineHeight
        self.letterSpacing = letterSpacing
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.shadowOffset = shadowOffset
    }
}

// MARK: - Edge Insets

/// Edge insets for padding/margin
public struct MonetixEdgeInsets: Codable, Sendable {
    public let top: CGFloat
    public let right: CGFloat
    public let bottom: CGFloat
    public let left: CGFloat

    public init(top: CGFloat = 0, right: CGFloat = 0, bottom: CGFloat = 0, left: CGFloat = 0) {
        self.top = top
        self.right = right
        self.bottom = bottom
        self.left = left
    }

    public init(all: CGFloat) {
        self.top = all
        self.right = all
        self.bottom = all
        self.left = all
    }

    public init(from decoder: Decoder) throws {
        // Support both number (all edges) and object format
        if let container = try? decoder.singleValueContainer(),
           let value = try? container.decode(CGFloat.self) {
            self.top = value
            self.right = value
            self.bottom = value
            self.left = value
        } else {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            top = try container.decodeIfPresent(CGFloat.self, forKey: .top) ?? 0
            right = try container.decodeIfPresent(CGFloat.self, forKey: .right) ?? 0
            bottom = try container.decodeIfPresent(CGFloat.self, forKey: .bottom) ?? 0
            left = try container.decodeIfPresent(CGFloat.self, forKey: .left) ?? 0
        }
    }

    enum CodingKeys: String, CodingKey {
        case top, right, bottom, left
    }
}

// MARK: - Dimension

/// Dimension value (can be number or "full"/"auto")
public enum MonetixDimension: Codable, Sendable {
    case fixed(CGFloat)
    case full
    case auto

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(CGFloat.self) {
            self = .fixed(value)
        } else if let str = try? container.decode(String.self) {
            switch str.lowercased() {
            case "full": self = .full
            case "auto": self = .auto
            default: self = .auto
            }
        } else {
            self = .auto
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .fixed(let value): try container.encode(value)
        case .full: try container.encode("full")
        case .auto: try container.encode("auto")
        }
    }
}

// MARK: - Offset

/// Offset for shadow
public struct MonetixOffset: Codable, Sendable {
    public let x: CGFloat
    public let y: CGFloat

    public init(x: CGFloat = 0, y: CGFloat = 0) {
        self.x = x
        self.y = y
    }
}

// MARK: - Background Configuration

/// Gradient overlay configuration for better text readability
public struct MonetixGradientOverlay: Codable, Sendable {
    public let enabled: Bool
    public let startColor: String // Bottom color (e.g., "rgba(0,0,0,0.8)")
    public let endColor: String   // Top color (e.g., "rgba(0,0,0,0)")
    
    public init(enabled: Bool = false, startColor: String = "rgba(0,0,0,0.8)", endColor: String = "rgba(0,0,0,0)") {
        self.enabled = enabled
        self.startColor = startColor
        self.endColor = endColor
    }
}

/// Background configuration for view
public struct MonetixBackgroundConfig: Codable, Sendable {
    /// Background type: color, image, or gradient
    public let type: String

    /// Image URL (for image type)
    public let url: String?

    /// Overlay color on top of image
    public let overlayColor: String?

    /// Overlay opacity (0.0 - 1.0)
    public let overlayOpacity: CGFloat?

    /// Gradient colors (for gradient type)
    public let gradientColors: [String]?

    /// Gradient direction
    public let gradientDirection: String?
    
    /// Bottom-to-top gradient overlay for text readability
    public let gradientOverlay: MonetixGradientOverlay?

    public init(
        type: String = "color",
        url: String? = nil,
        overlayColor: String? = nil,
        overlayOpacity: CGFloat? = nil,
        gradientColors: [String]? = nil,
        gradientDirection: String? = nil,
        gradientOverlay: MonetixGradientOverlay? = nil
    ) {
        self.type = type
        self.url = url
        self.overlayColor = overlayColor
        self.overlayOpacity = overlayOpacity
        self.gradientColors = gradientColors
        self.gradientDirection = gradientDirection
        self.gradientOverlay = gradientOverlay
    }
}

// MARK: - Feature Item

/// Feature item for feature list element
public struct MonetixFeatureItem: Codable, Sendable {
    public let icon: String
    public let text: String
    public let iconColor: String?

    /// SF Symbol name (e.g., "film.fill", "lock.fill")
    public let systemImage: String?

    public init(icon: String, text: String, iconColor: String? = nil, systemImage: String? = nil) {
        self.icon = icon
        self.text = text
        self.iconColor = iconColor
        self.systemImage = systemImage
    }
}

// MARK: - Paywall Element

/// A single element in the paywall
public struct MonetixPaywallElement: Codable, Sendable {
    /// Unique element ID
    public let id: String

    /// Element type
    public let type: MonetixPaywallElementType

    /// Element style
    public let style: MonetixElementStyle?

    // MARK: - Text Element Properties
    public let text: String?

    // MARK: - Image Element Properties
    public let url: String?
    public let contentMode: String?
    public let placeholder: String?

    // MARK: - Button Element Properties
    public let action: String?
    public let actionUrl: String?

    // MARK: - Product Element Properties
    public let productId: String?
    public let layout: String?
    public let showBadge: Bool?
    public let showDescription: Bool?
    public let showPrice: Bool?

    // MARK: - Feature List Properties
    public let features: [MonetixFeatureItem]?
    public let iconColor: String?

    // MARK: - Container/Stack Properties
    public let children: [MonetixPaywallElement]?
    public let spacing: CGFloat?
    public let axis: String?

    // MARK: - Spacer/Divider Properties
    public let size: CGFloat?
    public let flexible: Bool?
    public let thickness: CGFloat?

    // MARK: - Timer Properties
    public let endTime: String?
    public let format: String?
    public let expiredAction: String?
    public let expiredText: String?

    // MARK: - Badge Properties
    public let badgeText: String?

    // MARK: - Close Button Properties
    public let position: String?
    public let showDelay: TimeInterval?

    /// SF Symbol name (e.g., "xmark", "film.fill")
    public let systemImage: String?

    enum CodingKeys: String, CodingKey {
        case id, type, style
        case text, url, contentMode, placeholder
        case action, actionUrl
        case productId, layout, showBadge, showDescription, showPrice
        case features, iconColor
        case children, spacing, axis
        case size, flexible, thickness
        case endTime, format, expiredAction, expiredText
        case badgeText
        case position, showDelay
        case systemImage
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(MonetixPaywallElementType.self, forKey: .type)
        style = try container.decodeIfPresent(MonetixElementStyle.self, forKey: .style)

        text = try container.decodeIfPresent(String.self, forKey: .text)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        contentMode = try container.decodeIfPresent(String.self, forKey: .contentMode)
        placeholder = try container.decodeIfPresent(String.self, forKey: .placeholder)

        action = try container.decodeIfPresent(String.self, forKey: .action)
        actionUrl = try container.decodeIfPresent(String.self, forKey: .actionUrl)

        productId = try container.decodeIfPresent(String.self, forKey: .productId)
        layout = try container.decodeIfPresent(String.self, forKey: .layout)
        showBadge = try container.decodeIfPresent(Bool.self, forKey: .showBadge)
        showDescription = try container.decodeIfPresent(Bool.self, forKey: .showDescription)
        showPrice = try container.decodeIfPresent(Bool.self, forKey: .showPrice)

        features = try container.decodeIfPresent([MonetixFeatureItem].self, forKey: .features)
        iconColor = try container.decodeIfPresent(String.self, forKey: .iconColor)

        children = try container.decodeIfPresent([MonetixPaywallElement].self, forKey: .children)
        spacing = try container.decodeIfPresent(CGFloat.self, forKey: .spacing)
        axis = try container.decodeIfPresent(String.self, forKey: .axis)

        size = try container.decodeIfPresent(CGFloat.self, forKey: .size)
        flexible = try container.decodeIfPresent(Bool.self, forKey: .flexible)
        thickness = try container.decodeIfPresent(CGFloat.self, forKey: .thickness)

        endTime = try container.decodeIfPresent(String.self, forKey: .endTime)
        format = try container.decodeIfPresent(String.self, forKey: .format)
        expiredAction = try container.decodeIfPresent(String.self, forKey: .expiredAction)
        expiredText = try container.decodeIfPresent(String.self, forKey: .expiredText)

        badgeText = try container.decodeIfPresent(String.self, forKey: .badgeText)

        position = try container.decodeIfPresent(String.self, forKey: .position)
        showDelay = try container.decodeIfPresent(TimeInterval.self, forKey: .showDelay)
        systemImage = try container.decodeIfPresent(String.self, forKey: .systemImage)
    }

    public init(
        id: String,
        type: MonetixPaywallElementType,
        style: MonetixElementStyle? = nil,
        text: String? = nil,
        url: String? = nil,
        contentMode: String? = nil,
        placeholder: String? = nil,
        action: String? = nil,
        actionUrl: String? = nil,
        productId: String? = nil,
        layout: String? = nil,
        showBadge: Bool? = nil,
        showDescription: Bool? = nil,
        showPrice: Bool? = nil,
        features: [MonetixFeatureItem]? = nil,
        iconColor: String? = nil,
        children: [MonetixPaywallElement]? = nil,
        spacing: CGFloat? = nil,
        axis: String? = nil,
        size: CGFloat? = nil,
        flexible: Bool? = nil,
        thickness: CGFloat? = nil,
        endTime: String? = nil,
        format: String? = nil,
        expiredAction: String? = nil,
        expiredText: String? = nil,
        badgeText: String? = nil,
        position: String? = nil,
        showDelay: TimeInterval? = nil,
        systemImage: String? = nil
    ) {
        self.id = id
        self.type = type
        self.style = style
        self.text = text
        self.url = url
        self.contentMode = contentMode
        self.placeholder = placeholder
        self.action = action
        self.actionUrl = actionUrl
        self.productId = productId
        self.layout = layout
        self.showBadge = showBadge
        self.showDescription = showDescription
        self.showPrice = showPrice
        self.features = features
        self.iconColor = iconColor
        self.children = children
        self.spacing = spacing
        self.axis = axis
        self.size = size
        self.flexible = flexible
        self.thickness = thickness
        self.endTime = endTime
        self.format = format
        self.expiredAction = expiredAction
        self.expiredText = expiredText
        self.badgeText = badgeText
        self.position = position
        self.showDelay = showDelay
        self.systemImage = systemImage
    }
}

// MARK: - Element Convenience Extensions

public extension MonetixPaywallElement {
    /// Create a text element
    static func text(
        id: String,
        text: String,
        style: MonetixElementStyle? = nil
    ) -> MonetixPaywallElement {
        MonetixPaywallElement(id: id, type: .text, style: style, text: text)
    }

    /// Create an image element
    static func image(
        id: String,
        url: String,
        contentMode: String = "fit",
        style: MonetixElementStyle? = nil
    ) -> MonetixPaywallElement {
        MonetixPaywallElement(id: id, type: .image, style: style, url: url, contentMode: contentMode)
    }

    /// Create a button element
    static func button(
        id: String,
        text: String,
        action: String,
        style: MonetixElementStyle? = nil
    ) -> MonetixPaywallElement {
        MonetixPaywallElement(id: id, type: .button, style: style, text: text, action: action)
    }

    /// Create a spacer element
    static func spacer(
        id: String,
        size: CGFloat? = nil,
        flexible: Bool = false
    ) -> MonetixPaywallElement {
        MonetixPaywallElement(id: id, type: .spacer, size: size, flexible: flexible)
    }

    /// Create a divider element
    static func divider(
        id: String,
        thickness: CGFloat = 1,
        style: MonetixElementStyle? = nil
    ) -> MonetixPaywallElement {
        MonetixPaywallElement(id: id, type: .divider, style: style, thickness: thickness)
    }

    /// Create a product list element
    static func productList(
        id: String,
        layout: String = "vertical",
        showBadge: Bool = true,
        showDescription: Bool = true,
        showPrice: Bool = true,
        style: MonetixElementStyle? = nil
    ) -> MonetixPaywallElement {
        MonetixPaywallElement(
            id: id,
            type: .productList,
            style: style,
            layout: layout,
            showBadge: showBadge,
            showDescription: showDescription,
            showPrice: showPrice
        )
    }

    /// Create a purchase button element
    static func purchaseButton(
        id: String,
        productId: String,
        text: String,
        style: MonetixElementStyle? = nil
    ) -> MonetixPaywallElement {
        MonetixPaywallElement(
            id: id,
            type: .purchaseButton,
            style: style,
            text: text,
            productId: productId
        )
    }

    /// Create a close button element
    static func closeButton(
        id: String,
        position: String = "topRight",
        showDelay: TimeInterval = 0,
        style: MonetixElementStyle? = nil
    ) -> MonetixPaywallElement {
        MonetixPaywallElement(
            id: id,
            type: .closeButton,
            style: style,
            position: position,
            showDelay: showDelay
        )
    }

    /// Create a restore button element
    static func restoreButton(
        id: String,
        text: String = "Restore Purchases",
        style: MonetixElementStyle? = nil
    ) -> MonetixPaywallElement {
        MonetixPaywallElement(id: id, type: .restoreButton, style: style, text: text)
    }

    /// Create a feature list element
    static func featureList(
        id: String,
        features: [MonetixFeatureItem],
        iconColor: String? = nil,
        style: MonetixElementStyle? = nil
    ) -> MonetixPaywallElement {
        MonetixPaywallElement(
            id: id,
            type: .featureList,
            style: style,
            features: features,
            iconColor: iconColor
        )
    }

    /// Create a container element
    static func container(
        id: String,
        children: [MonetixPaywallElement],
        style: MonetixElementStyle? = nil
    ) -> MonetixPaywallElement {
        MonetixPaywallElement(id: id, type: .container, style: style, children: children)
    }

    /// Create a stack element
    static func stack(
        id: String,
        axis: String = "vertical",
        spacing: CGFloat = 0,
        children: [MonetixPaywallElement],
        style: MonetixElementStyle? = nil
    ) -> MonetixPaywallElement {
        MonetixPaywallElement(
            id: id,
            type: .stack,
            style: style,
            children: children,
            spacing: spacing,
            axis: axis
        )
    }
}
