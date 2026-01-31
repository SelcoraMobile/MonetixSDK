//
//  MonetixBuilderController.swift
//  MonetixSDK
//
//  Paywall Builder - Server-Driven UI Controller (UIKit)
//

#if canImport(UIKit)
import UIKit

/// Controller for rendering Paywall Builder paywalls (server-driven UI)
/// Use this when `paywall.usesPaywallBuilder` is true
@available(iOS 15.0, *)
public class MonetixBuilderController: UIViewController {

    // MARK: - Properties

    public weak var delegate: MonetixPaywallControllerDelegate?

    public let paywall: MonetixPaywall
    public let products: [MonetixProduct]
    private let viewConfiguration: MonetixViewConfiguration

    private var didCallStartPresenting = false
    private var selectedProduct: MonetixProduct?
    private var closeButtonView: UIView?
    private var closeButtonShowTimer: Timer?

    // MARK: - UI Components

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = true
        sv.alwaysBounceVertical = true
        return sv
    }()

    private lazy var contentStackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.alignment = .fill
        sv.distribution = .fill
        sv.spacing = 0
        return sv
    }()

    // MARK: - Initialization

    public init(paywall: MonetixPaywall, products: [MonetixProduct]) {
        guard let config = paywall.viewConfiguration else {
            fatalError("MonetixBuilderController requires a paywall with viewConfiguration. Check paywall.usesPaywallBuilder before initializing.")
        }
        self.paywall = paywall
        self.products = products
        self.viewConfiguration = config
        self.selectedProduct = products.first
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        closeButtonShowTimer?.invalidate()
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        renderElements()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !didCallStartPresenting {
            didCallStartPresenting = true
            delegate?.paywallControllerDidStartPresenting(self)
        }
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = UIColor(hex: viewConfiguration.backgroundColor)

        if viewConfiguration.scrollEnabled {
            view.addSubview(scrollView)

            var constraints = [
                scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ]

            if viewConfiguration.safeAreaTop {
                constraints.append(scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
            } else {
                constraints.append(scrollView.topAnchor.constraint(equalTo: view.topAnchor))
            }

            if viewConfiguration.safeAreaBottom {
                constraints.append(scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor))
            } else {
                constraints.append(scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor))
            }

            NSLayoutConstraint.activate(constraints)

            scrollView.addSubview(contentStackView)

            NSLayoutConstraint.activate([
                contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
                contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
            ])
        } else {
            view.addSubview(contentStackView)

            var constraints = [
                contentStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                contentStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ]

            if viewConfiguration.safeAreaTop {
                constraints.append(contentStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
            } else {
                constraints.append(contentStackView.topAnchor.constraint(equalTo: view.topAnchor))
            }

            if viewConfiguration.safeAreaBottom {
                constraints.append(contentStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor))
            } else {
                constraints.append(contentStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor))
            }

            NSLayoutConstraint.activate(constraints)
        }
    }

    // MARK: - Element Rendering

    private func renderElements() {
        for element in viewConfiguration.elements {
            if let view = createView(for: element) {
                contentStackView.addArrangedSubview(view)
            }
        }
    }

    private func createView(for element: MonetixPaywallElement) -> UIView? {
        switch element.type {
        case .text:
            return createTextView(element)
        case .image:
            return createImageView(element)
        case .button:
            return createButtonView(element)
        case .productList:
            return createProductListView(element)
        case .purchaseButton:
            return createPurchaseButton(element)
        case .featureList:
            return createFeatureListView(element)
        case .spacer:
            return createSpacerView(element)
        case .divider:
            return createDividerView(element)
        case .container:
            return createContainerView(element)
        case .stack:
            return createStackView(element)
        case .closeButton:
            return createCloseButton(element)
        case .restoreButton:
            return createRestoreButton(element)
        case .badge:
            return createBadgeView(element)
        case .timer, .video:
            // TODO: Implement timer and video elements
            return nil
        }
    }

    // MARK: - Text Element

    private func createTextView(_ element: MonetixPaywallElement) -> UIView {
        let label = UILabel()
        label.text = element.text
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        if let style = element.style {
            if let fontSize = style.fontSize {
                let weight = fontWeight(from: style.fontWeight)
                label.font = .systemFont(ofSize: CGFloat(fontSize), weight: weight)
            }
            if let color = style.color {
                label.textColor = UIColor(hex: color)
            }
            if let alignment = style.alignment {
                label.textAlignment = textAlignment(from: alignment)
            }
        }

        return wrapWithStyle(label, style: element.style)
    }

    // MARK: - Image Element

    private func createImageView(_ element: MonetixPaywallElement) -> UIView {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = contentMode(from: element.contentMode)
        imageView.clipsToBounds = true

        if let urlString = element.url, let url = URL(string: urlString) {
            loadImage(from: url, into: imageView)
        }

        if let style = element.style {
            if let cornerRadius = style.cornerRadius {
                imageView.layer.cornerRadius = cornerRadius
            }
            if let height = style.height {
                switch height {
                case .fixed(let value):
                    imageView.heightAnchor.constraint(equalToConstant: value).isActive = true
                default:
                    break
                }
            }
        }

        return wrapWithStyle(imageView, style: element.style)
    }

    private func loadImage(from url: URL, into imageView: UIImageView) {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        imageView.image = image
                    }
                }
            } catch {
                print("Failed to load image: \(error)")
            }
        }
    }

    // MARK: - Button Element

    private func createButtonView(_ element: MonetixPaywallElement) -> UIView {
        let button = UIButton(type: .system)
        button.setTitle(element.text, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tag = element.hashValue

        // Store action info
        objc_setAssociatedObject(button, &AssociatedKeys.action, element.action, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(button, &AssociatedKeys.actionUrl, element.actionUrl, .OBJC_ASSOCIATION_RETAIN)

        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)

        if let style = element.style {
            if let bgColor = style.backgroundColor {
                button.backgroundColor = UIColor(hex: bgColor)
            }
            if let textColor = style.textColor ?? style.color {
                button.setTitleColor(UIColor(hex: textColor), for: .normal)
            }
            if let fontSize = style.fontSize {
                let weight = fontWeight(from: style.fontWeight)
                button.titleLabel?.font = .systemFont(ofSize: CGFloat(fontSize), weight: weight)
            }
            if let cornerRadius = style.cornerRadius {
                button.layer.cornerRadius = cornerRadius
            }
            if let height = style.height {
                switch height {
                case .fixed(let value):
                    button.heightAnchor.constraint(equalToConstant: value).isActive = true
                default:
                    break
                }
            }
        }

        return wrapWithStyle(button, style: element.style)
    }

    @objc private func buttonTapped(_ sender: UIButton) {
        let action = objc_getAssociatedObject(sender, &AssociatedKeys.action) as? String
        let actionUrl = objc_getAssociatedObject(sender, &AssociatedKeys.actionUrl) as? String

        switch action {
        case "close":
            dismissPaywall()
        case "restore":
            restore()
        case "link":
            if let urlString = actionUrl, let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        case "custom":
            delegate?.paywallController(self, didPerformAction: actionUrl ?? "custom")
        default:
            break
        }
    }

    // MARK: - Product List Element

    private func createProductListView(_ element: MonetixPaywallElement) -> UIView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = element.layout == "horizontal" ? .horizontal : .vertical
        stackView.spacing = 12
        stackView.distribution = .fillEqually

        for product in products {
            let productView = createProductCard(
                for: product,
                showBadge: element.showBadge ?? true,
                showDescription: element.showDescription ?? true,
                showPrice: element.showPrice ?? true
            )
            stackView.addArrangedSubview(productView)
        }

        return wrapWithStyle(stackView, style: element.style)
    }

    private func createProductCard(
        for product: MonetixProduct,
        showBadge: Bool,
        showDescription: Bool,
        showPrice: Bool
    ) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = selectedProduct?.id == product.id ? UIColor.systemBlue.withAlphaComponent(0.1) : UIColor.secondarySystemBackground
        card.layer.cornerRadius = 12
        card.layer.borderWidth = selectedProduct?.id == product.id ? 2 : 1
        card.layer.borderColor = selectedProduct?.id == product.id ? UIColor.systemBlue.cgColor : UIColor.separator.cgColor

        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading

        let titleLabel = UILabel()
        titleLabel.text = product.localizedTitle
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)

        stack.addArrangedSubview(titleLabel)

        if showDescription, let description = product.localizedDescription {
            let descLabel = UILabel()
            descLabel.text = description
            descLabel.font = .systemFont(ofSize: 13)
            descLabel.textColor = .secondaryLabel
            descLabel.numberOfLines = 2
            stack.addArrangedSubview(descLabel)
        }

        if showPrice {
            let priceLabel = UILabel()
            priceLabel.text = product.localizedPrice
            priceLabel.font = .systemFont(ofSize: 15, weight: .medium)
            priceLabel.textColor = .systemBlue
            stack.addArrangedSubview(priceLabel)
        }

        card.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
        ])

        // Make tappable
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(productCardTapped(_:)))
        card.addGestureRecognizer(tapGesture)
        card.isUserInteractionEnabled = true
        objc_setAssociatedObject(card, &AssociatedKeys.product, product, .OBJC_ASSOCIATION_RETAIN)

        return card
    }

    @objc private func productCardTapped(_ gesture: UITapGestureRecognizer) {
        guard let card = gesture.view,
              let product = objc_getAssociatedObject(card, &AssociatedKeys.product) as? MonetixProduct else {
            return
        }

        selectedProduct = product
        delegate?.paywallController(self, didSelectProduct: product)

        // Refresh product list
        // In a real implementation, you'd update the UI to reflect selection
    }

    // MARK: - Purchase Button Element

    private func createPurchaseButton(_ element: MonetixPaywallElement) -> UIView {
        let button = UIButton(type: .system)
        button.setTitle(element.text ?? "Continue", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.layer.cornerRadius = 12

        if let productId = element.productId {
            objc_setAssociatedObject(button, &AssociatedKeys.productId, productId, .OBJC_ASSOCIATION_RETAIN)
        }

        button.addTarget(self, action: #selector(purchaseButtonTapped(_:)), for: .touchUpInside)

        if let style = element.style {
            if let bgColor = style.backgroundColor {
                button.backgroundColor = UIColor(hex: bgColor)
            }
            if let textColor = style.textColor {
                button.setTitleColor(UIColor(hex: textColor), for: .normal)
            }
            if let cornerRadius = style.cornerRadius {
                button.layer.cornerRadius = cornerRadius
            }
            if let fontSize = style.fontSize {
                let weight = fontWeight(from: style.fontWeight)
                button.titleLabel?.font = .systemFont(ofSize: CGFloat(fontSize), weight: weight)
            }
        }

        button.heightAnchor.constraint(equalToConstant: 50).isActive = true

        return wrapWithStyle(button, style: element.style)
    }

    @objc private func purchaseButtonTapped(_ sender: UIButton) {
        let productId = objc_getAssociatedObject(sender, &AssociatedKeys.productId) as? String

        var productToPurchase: MonetixProduct?

        if let productId = productId {
            productToPurchase = products.first { $0.id == productId || $0.vendorProductId == productId }
        } else {
            productToPurchase = selectedProduct ?? products.first
        }

        if let product = productToPurchase {
            purchase(product: product)
        }
    }

    // MARK: - Feature List Element

    private func createFeatureListView(_ element: MonetixPaywallElement) -> UIView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 12

        let iconColor = element.iconColor ?? "#34C759"

        for feature in element.features ?? [] {
            let featureView = createFeatureRow(icon: feature.icon, text: feature.text, iconColor: feature.iconColor ?? iconColor)
            stackView.addArrangedSubview(featureView)
        }

        return wrapWithStyle(stackView, style: element.style)
    }

    private func createFeatureRow(icon: String, text: String, iconColor: String) -> UIView {
        let hStack = UIStackView()
        hStack.axis = .horizontal
        hStack.spacing = 12
        hStack.alignment = .center

        let iconLabel = UILabel()
        iconLabel.text = systemIcon(for: icon)
        iconLabel.font = .systemFont(ofSize: 20)
        iconLabel.textColor = UIColor(hex: iconColor)
        iconLabel.widthAnchor.constraint(equalToConstant: 24).isActive = true

        let textLabel = UILabel()
        textLabel.text = text
        textLabel.font = .systemFont(ofSize: 15)
        textLabel.numberOfLines = 0

        hStack.addArrangedSubview(iconLabel)
        hStack.addArrangedSubview(textLabel)

        return hStack
    }

    private func systemIcon(for iconName: String) -> String {
        // Map common icon names to SF Symbols or emoji
        let iconMap: [String: String] = [
            "check": "checkmark.circle.fill",
            "star": "star.fill",
            "heart": "heart.fill",
            "lightning": "bolt.fill",
            "infinity": "infinity",
            "lock": "lock.fill",
            "unlock": "lock.open.fill",
            "crown": "crown.fill",
            "gift": "gift.fill",
            "sparkle": "sparkles"
        ]

        if let mapped = iconMap[iconName.lowercased()] {
            if let image = UIImage(systemName: mapped) {
                // Return checkmark for now, actual implementation would use image
                return "✓"
            }
        }

        // Return the icon as-is (might be an emoji)
        return iconName
    }

    // MARK: - Spacer Element

    private func createSpacerView(_ element: MonetixPaywallElement) -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false

        if let size = element.size {
            view.heightAnchor.constraint(equalToConstant: size).isActive = true
        } else if element.flexible == true {
            view.setContentHuggingPriority(.defaultLow, for: .vertical)
            view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        } else {
            view.heightAnchor.constraint(equalToConstant: 16).isActive = true
        }

        return view
    }

    // MARK: - Divider Element

    private func createDividerView(_ element: MonetixPaywallElement) -> UIView {
        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = UIColor.separator

        if let style = element.style, let color = style.backgroundColor ?? style.color {
            divider.backgroundColor = UIColor(hex: color)
        }

        let thickness = element.thickness ?? 1
        divider.heightAnchor.constraint(equalToConstant: thickness).isActive = true

        return wrapWithStyle(divider, style: element.style)
    }

    // MARK: - Container Element

    private func createContainerView(_ element: MonetixPaywallElement) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        if let style = element.style {
            if let bgColor = style.backgroundColor {
                container.backgroundColor = UIColor(hex: bgColor)
            }
            if let cornerRadius = style.cornerRadius {
                container.layer.cornerRadius = cornerRadius
            }
            if let borderWidth = style.borderWidth {
                container.layer.borderWidth = borderWidth
            }
            if let borderColor = style.borderColor {
                container.layer.borderColor = UIColor(hex: borderColor).cgColor
            }
        }

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 0

        for child in element.children ?? [] {
            if let childView = createView(for: child) {
                stackView.addArrangedSubview(childView)
            }
        }

        container.addSubview(stackView)

        let padding = element.style?.padding ?? MonetixEdgeInsets(all: 0)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: container.topAnchor, constant: padding.top),
            stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -padding.bottom),
            stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: padding.left),
            stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -padding.right)
        ])

        return wrapWithStyle(container, style: element.style, skipPadding: true)
    }

    // MARK: - Stack Element

    private func createStackView(_ element: MonetixPaywallElement) -> UIView {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = element.axis == "horizontal" ? .horizontal : .vertical
        stackView.spacing = element.spacing ?? 0
        stackView.alignment = .fill
        stackView.distribution = .fill

        for child in element.children ?? [] {
            if let childView = createView(for: child) {
                stackView.addArrangedSubview(childView)
            }
        }

        return wrapWithStyle(stackView, style: element.style)
    }

    // MARK: - Close Button Element

    private func createCloseButton(_ element: MonetixPaywallElement) -> UIView? {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = element.style?.color.flatMap { UIColor(hex: $0) } ?? .label
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)

        button.widthAnchor.constraint(equalToConstant: 44).isActive = true
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true

        // Position the close button
        view.addSubview(button)

        let position = element.position ?? "topRight"
        switch position {
        case "topLeft":
            NSLayoutConstraint.activate([
                button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
                button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8)
            ])
        default: // topRight
            NSLayoutConstraint.activate([
                button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
                button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8)
            ])
        }

        // Handle show delay
        if let delay = element.showDelay, delay > 0 {
            button.alpha = 0
            closeButtonView = button
            closeButtonShowTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                UIView.animate(withDuration: 0.3) {
                    self?.closeButtonView?.alpha = 1
                }
            }
        }

        return nil // Don't add to stack, already added to view
    }

    @objc private func closeButtonTapped() {
        dismissPaywall()
    }

    // MARK: - Restore Button Element

    private func createRestoreButton(_ element: MonetixPaywallElement) -> UIView {
        let button = UIButton(type: .system)
        button.setTitle(element.text ?? "Restore Purchases", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(restoreButtonTapped), for: .touchUpInside)

        if let style = element.style {
            if let color = style.color ?? style.textColor {
                button.setTitleColor(UIColor(hex: color), for: .normal)
            }
            if let fontSize = style.fontSize {
                button.titleLabel?.font = .systemFont(ofSize: CGFloat(fontSize))
            }
        } else {
            button.setTitleColor(.secondaryLabel, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 14)
        }

        return wrapWithStyle(button, style: element.style)
    }

    @objc private func restoreButtonTapped() {
        restore()
    }

    // MARK: - Badge Element

    private func createBadgeView(_ element: MonetixPaywallElement) -> UIView {
        let label = PaddedLabel()
        label.text = element.badgeText ?? element.text
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.clipsToBounds = true

        if let style = element.style {
            if let bgColor = style.backgroundColor {
                label.backgroundColor = UIColor(hex: bgColor)
            } else {
                label.backgroundColor = .systemBlue
            }
            if let textColor = style.textColor ?? style.color {
                label.textColor = UIColor(hex: textColor)
            } else {
                label.textColor = .white
            }
            if let cornerRadius = style.cornerRadius {
                label.layer.cornerRadius = cornerRadius
            } else {
                label.layer.cornerRadius = 4
            }
        } else {
            label.backgroundColor = .systemBlue
            label.textColor = .white
            label.layer.cornerRadius = 4
        }

        label.padding = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

        return wrapWithStyle(label, style: element.style)
    }

    // MARK: - Style Helpers

    private func wrapWithStyle(_ view: UIView, style: MonetixElementStyle?, skipPadding: Bool = false) -> UIView {
        guard let style = style else { return view }

        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(view)

        let margin = style.margin ?? MonetixEdgeInsets(all: 0)
        let padding = skipPadding ? MonetixEdgeInsets(all: 0) : (style.padding ?? MonetixEdgeInsets(all: 0))

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: margin.top + padding.top),
            view.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -(margin.bottom + padding.bottom)),
            view.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: margin.left + padding.left),
            view.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -(margin.right + padding.right))
        ])

        if let opacity = style.opacity {
            wrapper.alpha = opacity
        }

        return wrapper
    }

    private func fontWeight(from string: String?) -> UIFont.Weight {
        switch string?.lowercased() {
        case "bold": return .bold
        case "semibold": return .semibold
        case "medium": return .medium
        case "light": return .light
        case "thin": return .thin
        default: return .regular
        }
    }

    private func textAlignment(from string: String?) -> NSTextAlignment {
        switch string?.lowercased() {
        case "left": return .left
        case "right": return .right
        case "center": return .center
        default: return .natural
        }
    }

    private func contentMode(from string: String?) -> UIView.ContentMode {
        switch string?.lowercased() {
        case "fit": return .scaleAspectFit
        case "fill": return .scaleAspectFill
        case "stretch": return .scaleToFill
        default: return .scaleAspectFit
        }
    }

    // MARK: - Actions

    private func dismissPaywall() {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.paywallControllerDidDismiss(self)
        }
    }

    /// Initiate purchase for a product
    public func purchase(product: MonetixProduct) {
        Task { @MainActor in
            do {
                let result = try await Monetix.shared.makePurchase(product: product)

                if result.isPurchaseCancelled {
                    delegate?.paywallController(self, didCancelPurchase: product)
                } else {
                    delegate?.paywallController(self, didFinishPurchase: product, purchaseResult: result)
                }
            } catch let error as MonetixError {
                delegate?.paywallController(self, didFailPurchase: product, error: error)
            } catch {
                delegate?.paywallController(
                    self,
                    didFailPurchase: product,
                    error: .unknownError(error.localizedDescription)
                )
            }
        }
    }

    /// Restore purchases
    public func restore() {
        Task { @MainActor in
            do {
                let profile = try await Monetix.shared.restorePurchases()
                delegate?.paywallController(self, didFinishRestoreWith: profile)
            } catch let error as MonetixError {
                delegate?.paywallController(self, didFailRestoreWith: error)
            } catch {
                delegate?.paywallController(
                    self,
                    didFailRestoreWith: .unknownError(error.localizedDescription)
                )
            }
        }
    }
}

// MARK: - Associated Keys

private struct AssociatedKeys {
    static var action = "monetix_action"
    static var actionUrl = "monetix_actionUrl"
    static var product = "monetix_product"
    static var productId = "monetix_productId"
}

// MARK: - UIColor Extension

extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r, g, b, a: CGFloat
        switch hexSanitized.count {
        case 6:
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
            a = 1.0
        case 8:
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        default:
            r = 0
            g = 0
            b = 0
            a = 1.0
        }

        self.init(red: r, green: g, blue: b, alpha: a)
    }
}

// MARK: - Padded Label

private class PaddedLabel: UILabel {
    var padding: UIEdgeInsets = .zero

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + padding.left + padding.right,
            height: size.height + padding.top + padding.bottom
        )
    }
}

#endif
