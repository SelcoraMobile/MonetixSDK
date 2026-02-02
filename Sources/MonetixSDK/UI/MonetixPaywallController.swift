//
//  MonetixPaywallController.swift
//  MonetixSDK
//
//  Created by MonetixSDK
//

#if canImport(UIKit)
import UIKit

/// Base paywall view controller with default UI for Remote Config paywalls
/// Can be subclassed for custom UIs
@available(iOS 15.0, *)
open class MonetixPaywallController: UIViewController {
    public weak var delegate: MonetixPaywallControllerDelegate?

    public let paywall: MonetixPaywall
    public let products: [MonetixProduct]

    private var didCallStartPresenting = false
    private var selectedProduct: MonetixProduct?
    private var productButtons: [UIButton] = []
    private var purchaseButton: UIButton?
    private var isLoading = false {
        didSet {
            updateLoadingState()
        }
    }

    // MARK: - UI Components

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = true
        sv.alwaysBounceVertical = true
        return sv
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .label
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = paywall.name.isEmpty ? "Premium" : paywall.name
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var productsStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 12
        sv.alignment = .fill
        sv.distribution = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private lazy var restoreButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Restore Purchases", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(restoreButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Initialization

    public init(paywall: MonetixPaywall, products: [MonetixProduct]) {
        self.paywall = paywall
        self.products = products
        self.selectedProduct = products.first
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    open override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !didCallStartPresenting {
            didCallStartPresenting = true
            delegate?.paywallControllerDidStartPresenting(self)
        }
    }

    // MARK: - UI Setup

    /// Override this method to setup your custom UI
    open func setupUI() {
        view.backgroundColor = .systemBackground

        // Add scroll view
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Add close button
        view.addSubview(closeButton)

        // Add loading indicator
        view.addSubview(loadingIndicator)

        // Setup constraints for scroll view
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        // Close button constraints
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        // Loading indicator constraints
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        // Add content
        contentView.addSubview(titleLabel)
        contentView.addSubview(productsStackView)
        contentView.addSubview(restoreButton)

        // Title constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 80),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24)
        ])

        // Products stack constraints
        NSLayoutConstraint.activate([
            productsStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 32),
            productsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            productsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24)
        ])

        // Create product cards
        createProductCards()

        // Create purchase button
        let purchaseBtn = createPurchaseButton()
        self.purchaseButton = purchaseBtn
        contentView.addSubview(purchaseBtn)

        NSLayoutConstraint.activate([
            purchaseBtn.topAnchor.constraint(equalTo: productsStackView.bottomAnchor, constant: 24),
            purchaseBtn.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            purchaseBtn.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            purchaseBtn.heightAnchor.constraint(equalToConstant: 56)
        ])

        // Restore button constraints
        NSLayoutConstraint.activate([
            restoreButton.topAnchor.constraint(equalTo: purchaseBtn.bottomAnchor, constant: 16),
            restoreButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            restoreButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])

        updateSelectedProductUI()
    }

    private func createProductCards() {
        productButtons.removeAll()
        productsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (index, product) in products.enumerated() {
            let card = createProductCard(for: product, index: index)
            productsStackView.addArrangedSubview(card)

            // Add tap gesture
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(productCardTapped(_:)))
            card.addGestureRecognizer(tapGesture)
            card.isUserInteractionEnabled = true
            card.tag = index
        }
    }

    private func createProductCard(for product: MonetixProduct, index: Int) -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 2
        card.layer.borderColor = UIColor.clear.cgColor
        card.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = product.localizedTitle
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let priceLabel = UILabel()
        priceLabel.text = product.localizedPrice ?? "\(product.price)"
        priceLabel.font = .systemFont(ofSize: 15, weight: .medium)
        priceLabel.textColor = .systemBlue
        priceLabel.translatesAutoresizingMaskIntoConstraints = false

        let descLabel = UILabel()
        descLabel.text = product.localizedDescription.isEmpty ? nil : product.localizedDescription
        descLabel.font = .systemFont(ofSize: 13)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 2
        descLabel.translatesAutoresizingMaskIntoConstraints = false

        let checkmark = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        checkmark.tintColor = .systemBlue
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        checkmark.isHidden = true
        checkmark.tag = 1000 + index

        card.addSubview(titleLabel)
        card.addSubview(priceLabel)
        card.addSubview(descLabel)
        card.addSubview(checkmark)

        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),

            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: checkmark.leadingAnchor, constant: -8),

            priceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            priceLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),

            descLabel.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 4),
            descLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            descLabel.trailingAnchor.constraint(equalTo: checkmark.leadingAnchor, constant: -8),
            descLabel.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -16),

            checkmark.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            checkmark.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            checkmark.widthAnchor.constraint(equalToConstant: 24),
            checkmark.heightAnchor.constraint(equalToConstant: 24)
        ])

        productButtons.append(UIButton()) // placeholder for tracking

        return card
    }

    private func createPurchaseButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("Continue", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(purchaseButtonTapped), for: .touchUpInside)
        return button
    }

    @objc private func productCardTapped(_ gesture: UITapGestureRecognizer) {
        guard let card = gesture.view else { return }
        let index = card.tag
        guard index < products.count else { return }

        selectedProduct = products[index]
        updateSelectedProductUI()
    }

    private func updateSelectedProductUI() {
        for (index, _) in products.enumerated() {
            guard let card = productsStackView.arrangedSubviews[safe: index] else { continue }
            let isSelected = products[index].id == selectedProduct?.id

            card.layer.borderColor = isSelected ? UIColor.systemBlue.cgColor : UIColor.clear.cgColor
            card.backgroundColor = isSelected ? UIColor.systemBlue.withAlphaComponent(0.1) : .secondarySystemBackground

            if let checkmark = card.viewWithTag(1000 + index) as? UIImageView {
                checkmark.isHidden = !isSelected
            }
        }
    }

    private func updateLoadingState() {
        if isLoading {
            loadingIndicator.startAnimating()
            purchaseButton?.isEnabled = false
            purchaseButton?.alpha = 0.6
        } else {
            loadingIndicator.stopAnimating()
            purchaseButton?.isEnabled = true
            purchaseButton?.alpha = 1.0
        }
    }

    // MARK: - Actions

    @objc private func closeButtonTapped() {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.paywallControllerDidDismiss(self)
        }
    }

    @objc private func purchaseButtonTapped() {
        guard let product = selectedProduct else { return }
        purchase(product: product)
    }

    @objc private func restoreButtonTapped() {
        restore()
    }

    // MARK: - Purchase Helpers

    /// Initiate purchase for a product
    public func purchase(product: MonetixProduct) {
        isLoading = true

        Task { @MainActor in
            do {
                let result = try await Monetix.shared.makePurchase(product: product)
                isLoading = false

                if result.isPurchaseCancelled {
                    delegate?.paywallController(self, didCancelPurchase: product)
                } else {
                    delegate?.paywallController(self, didFinishPurchase: product, purchaseResult: result)
                }
            } catch let error as MonetixError {
                isLoading = false
                delegate?.paywallController(self, didFailPurchase: product, error: error)
            } catch {
                isLoading = false
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
        isLoading = true

        Task { @MainActor in
            do {
                let profile = try await Monetix.shared.restorePurchases()
                isLoading = false
                delegate?.paywallController(self, didFinishRestoreWith: profile)
            } catch let error as MonetixError {
                isLoading = false
                delegate?.paywallController(self, didFailRestoreWith: error)
            } catch {
                isLoading = false
                delegate?.paywallController(
                    self,
                    didFailRestoreWith: .unknownError(error.localizedDescription)
                )
            }
        }
    }
}

// MARK: - Array Extension

private extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
#endif
