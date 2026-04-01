import UIKit
import ApplePay_iOS

class TapApplePayExampleViewController: UIViewController {

    // MARK: - UI

    private let applePayView       = ApplePayView()
    private let eventsTextView     = UITextView()
    private let refreshButton      = UIButton(type: .system)
    private let scrollView         = UIScrollView()
    private let contentStack       = UIStackView()

    // MARK: - Config

    /// Default config matching the Apple Pay button props.
    var config: [String: Any] = [
        // REQUIRED: Scope determines the type of token generated
        // Scope: 'AppleToken' | 'TapToken'
        "scope": "AppleToken",
        
        // REQUIRED: Your Tap public key for authentication
        "publicKey": "pk_test_Vlk842B1EA7tDN5QbrfGjYzh",
        
        // REQUIRED: Merchant information
        "merchant": [
            "id": "1124340",
        ],
        
        // OPTIONAL: Interface customization
        "interface": [
            // Locale: 'en' | 'ar' (optional, defaults to 'en')
            "locale": "en",
            // ThemeMode: 'dark' | 'light' (optional, defaults to 'light')
            "theme":  "dark",
            // Edges: 'straight' | 'curved' (optional, defaults to 'curved')
            "edges":  "curved",
            // ButtonType: 'book' | 'buy' | 'check-out' | 'pay' | 'plain' | 'subscribe' (optional)
            "type":   "buy",
        ],
        
        // REQUIRED: Customer information
        "customer": [
            // Option 1: Provide customer ID if customer already exists
            // "id": "cust_123",
            
            // Option 2: Provide customer details (use this if no ID)
            "name": [
                [
                    // Locale: 'en' | 'ar' | 'fr' (required)
                    "lang":   "en",
                    // First name (required)
                    "first":  "John",
                    // Last name (required)
                    "last":   "Smith",
                    // Middle name (optional)
                    "middle": "David",
                ],
            ],
            // REQUIRED: Must have at least email or phone number
            "contact": [
                // Email address (optional if phone is provided)
                "email": "john.smith@example.com",
                // Phone number (optional if email is provided)
                "phone": [
                    // Country code with + prefix (required if phone provided)
                    "countryCode": "+1",
                    // Phone number (required if phone provided)
                    "number":      "5551234567",
                ],
            ],
        ],
        
        // REQUIRED: Payment acceptance settings
        "acceptance": [
            // SupportedNetworks (each element): 'amex' | 'mada' | 'masterCard' | 'visa' | 'chinaUnionPay' | 'discover' | 'electron' | 'jcb' | 'maestro'
            "supportedBrands":    ["visa", "masterCard"],
            // Supported card types: "credit" and/or "debit" (optional)
           "supportedCards":     ["debit"],
            // Supported regions for payments (optional)
            "supportedRegions":   ["LOCAL", "REGIONAL", "GLOBAL"],
            // Supported countries for payments (optional)
            "supportedCountries": ["AE", "KW", "SA", "QA", "BH", "OM", "EG", "JO", "LB"],
        ],
        
        // REQUIRED: Transaction details
        "transaction": [
            // Transaction amount as string (required)
            "amount":     "20.00",
            // ISO 4217 currency code (required)
            "currency":   "KWD",
            // Coupon code for discount (optional)
//            "couponCode": "SAVE10",
            // Shipping options (optional, only if shipping is applicable)
//            "shipping": [
//                [
//                    // Shipping method label (required)
//                    "label":      "Standard Shipping",
//                    // Shipping description (required)
//                    "detail":     "5–7 business days",
//                    // Shipping cost (required)
//                    "amount":     "1.00",
//                    // Unique identifier (required)
//                    "identifier": "std",
//                ],
//                [
//                    "label":      "Express Shipping",
//                    "detail":     "1–2 business days",
//                    "amount":     "5.00",
//                    "identifier": "exp",
//                ],
//            ],
            // Line items for the transaction (optional)
//            "items": [
//                [
//                    // Item type: 'final' | 'pending' (required)
//                    "type":          "final",
//                    // Item label/description (required)
//                    "label":         "Product Order",
//                    // Item amount (required)
//                    "amount":        "20.00",
//                    // Payment timing: 'immediate' | 'recurring' | 'deferred' | 'automaticReload' (required)
//                    "paymentTiming": "immediate",
//                ],
//            ],
        ],
        
        // OPTIONAL: Additional features
        "features": [
            // Allow coupon code entry (optional, defaults to false)
//            "supportsCouponCode": true,
//            "shippingContactFields": ["name", "phone", "email"],
        ],
    ]

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Tap Apple Pay"
        view.backgroundColor = .systemBackground
        setupNavigationBar()
        setupLayout()
        startApplePay()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Options",
            style: .plain,
            target: self,
            action: #selector(optionsTapped)
        )
    }

    private func setupLayout() {
        // Apple Pay button
        applePayView.translatesAutoresizingMaskIntoConstraints = false
        applePayView.backgroundColor = .clear

        // Events text view
        eventsTextView.isEditable = false
        eventsTextView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        eventsTextView.backgroundColor = UIColor.secondarySystemBackground
        eventsTextView.layer.cornerRadius = 8
        eventsTextView.text = "Events will appear here..."
        eventsTextView.translatesAutoresizingMaskIntoConstraints = false

        // Refresh button
        refreshButton.setTitle("Reload Button", for: .normal)
        refreshButton.addTarget(self, action: #selector(refreshTapped), for: .touchUpInside)
        refreshButton.isHidden = true
        refreshButton.translatesAutoresizingMaskIntoConstraints = false

        // Stack
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(applePayView)
        contentStack.addArrangedSubview(eventsTextView)
        contentStack.addArrangedSubview(refreshButton)

        // Scroll
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),

            applePayView.heightAnchor.constraint(equalToConstant: 100),
            eventsTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 250),
        ])
    }

    // MARK: - Apple Pay

    private func startApplePay() {
        refreshButton.isHidden = true
        eventsTextView.text = ""
        applePayView.initApplePay(configDict: config, delegate: self)
    }

    // MARK: - Actions

    @objc private func refreshTapped() {
        startApplePay()
    }

    @objc private func optionsTapped() {
        let sheet = UIAlertController(title: "Options", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(.init(title: "Copy logs", style: .default) { _ in
            UIPasteboard.general.string = self.eventsTextView.text
        })
        sheet.addAction(.init(title: "Clear logs", style: .default) { _ in
            self.eventsTextView.text = ""
        })
        sheet.addAction(.init(title: "Settings", style: .default) { _ in
            self.openSettings()
        })
        sheet.addAction(.init(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }

    private func openSettings() {
        let settingsVC = TapApplePaySettingsViewController()
        settingsVC.config = config
        settingsVC.delegate = self
        navigationController?.pushViewController(settingsVC, animated: true)
    }

    // MARK: - Event logging

    private func log(_ event: String) {
        let existing = eventsTextView.text ?? ""
        eventsTextView.text = "\n\n========\n\n\(event)\(existing)"
    }
}

// MARK: - TapApplePayDelegate

extension TapApplePayExampleViewController: ApplePayDelegate {
    func onReady() {
        log("onReady")
    }

    func onClick() {
        log("onClick")
    }

    func onCanceled() {
        log("onCanceled")
        refreshButton.isHidden = false
    }

    func onError(data: String) {
        log("onError:\n\(prettyJSON(data))")
        refreshButton.isHidden = false
    }

    func onSuccess(data: String) {
        log("onSuccess:\n\(prettyJSON(data))")
        refreshButton.isHidden = false

        let successVC = TapApplePayOnSuccessViewController()
        successVC.resultString = prettyJSON(data)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.navigationController?.pushViewController(successVC, animated: true)
        }
    }

    func onOrderCreated(data: String) {
        log("onOrderCreated: \(data)")
    }

    func onChargeCreated(data: String) {
        log("onChargeCreated: \(data)")
    }

    func onMerchantValidation(data: String) {
        log("onMerchantValidation:\n\(prettyJSON(data))")
    }

    private func prettyJSON(_ jsonString: String) -> String {
        guard let data = jsonString.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: obj, options: .prettyPrinted) else {
            return jsonString
        }
        return String(decoding: pretty, as: UTF8.self)
    }
}

// MARK: - Settings delegate

extension TapApplePayExampleViewController: TapApplePaySettingsDelegate {
    func didUpdateConfig(_ config: [String: Any]) {
        self.config = config
        startApplePay()
    }
}
