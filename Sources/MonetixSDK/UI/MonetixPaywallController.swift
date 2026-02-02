//
//  MonetixPaywallController.swift
//  MonetixSDK
//
//  Created by MonetixSDK
//

#if canImport(UIKit)
import UIKit

/// Base paywall view controller (can be subclassed for custom UIs)
@available(iOS 15.0, *)
open class MonetixPaywallController: UIViewController {
    public weak var delegate: MonetixPaywallControllerDelegate?

    public let paywall: MonetixPaywall
    public let products: [MonetixProduct]

    private var didCallStartPresenting = false

    public init(paywall: MonetixPaywall, products: [MonetixProduct]) {
        self.paywall = paywall
        self.products = products
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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

    /// Override this method to setup your custom UI
    open func setupUI() {
        view.backgroundColor = .systemBackground

        // This is a basic implementation - override in your custom controller
        let label = UILabel()
        label.text = "Override setupUI() to customize this paywall"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        // Add close button
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Close", for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    @objc private func closeButtonTapped() {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.paywallControllerDidDismiss(self)
        }
    }

    // MARK: - Purchase Helpers

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
#endif
