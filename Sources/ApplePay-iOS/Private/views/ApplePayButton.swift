import UIKit
import WebKit
import PassKit
import SharedDataModels_iOS

/// The core WKWebView-based Apple Pay button view.
///
/// Flow 
///   1. `initApplePay` POSTs the config dict to the Tap button config API
///   2. The API returns `{ "redirect_url": "..." }`
///   3. That URL is loaded into the embedded WKWebView
///   4. The web SDK fires callbacks back via the `tapapplepaywebsdk://` custom URL scheme
internal class ApplePayButton: UIView {

    internal var webView: WKWebView = .init()
    internal var delegate: ApplePayDelegate?
    /// The redirect URL returned by the button config API (kept for reloads)
    internal var currentRedirectURL: URL?
    /// The original config dict (kept for locale helpers)
    internal var currentConfig: [String: Any] = [:]
    internal var threeDsView: ThreeDSViewController?
    /// Shimmer overlay shown while the web SDK is loading
    internal var shimmerView: TapShimmerView?

    /// Fixed-height container centred inside `ApplePayButton`.
    /// All child views (webView, shimmer, PKPaymentButton) live here so that
    /// the outer view can be any height while the button area stays 48 pt tall.
    internal let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    #if targetEnvironment(simulator)
    /// Native PKPaymentButton shown in the Simulator once `onReady` fires.
    /// On a real device the webView renders the Tap web button as normal.
    internal var simulatorPayButton: PKPaymentButton?
    #endif

    // MARK: - Computed helpers (read directly from config dict)

    internal var currentLocale: String {
        (currentConfig["interface"] as? [String: Any])?["locale"] as? String ?? "en"
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        setupContainerView()
        setupWebView()
        setupConstraints()
    }

    // MARK: - Container view

    private func setupContainerView() {
        addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 48),
        ])
    }

    // MARK: - WebView setup

    private func setupWebView() {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.bounces = false
        webView.scrollView.showsVerticalScrollIndicator = false
        #if targetEnvironment(simulator)
        webView.isHidden = true
        #endif
        containerView.addSubview(webView)
    }

    private func setupConstraints() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: containerView.topAnchor),
            webView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
        containerView.layoutIfNeeded()
        layoutIfNeeded()
    }

    // MARK: - Shimmer

    internal func showShimmer() {
        shimmerView?.removeFromSuperview()
        let s = TapShimmerView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.applyInterfaceConfig(currentConfig["interface"] as? [String: Any] ?? [:])
        containerView.addSubview(s)
        NSLayoutConstraint.activate([
            s.topAnchor.constraint(equalTo: containerView.topAnchor),
            s.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            s.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            s.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
        shimmerView = s
    }

    internal func hideShimmer() {
        shimmerView?.hideAnimated()
        shimmerView = nil
    }

    // MARK: - URL loading

    internal func openUrl(url: URL) {
        currentRedirectURL = url
        var request = URLRequest(url: url)
        // Mirror Card-iOS: set bundle ID as the referer header
        request.setValue(
            TapApplicationPlistInfo.shared.bundleIdentifier ?? "",
            forHTTPHeaderField: "referer"
        )
        DispatchQueue.main.async {
            self.webView.navigationDelegate = self
            self.webView.uiDelegate = self
            if #available(iOS 16.4, *) {
                self.webView.isInspectable = true
            } else {
                // Fallback on earlier versions
            }
            self.webView.load(request)
        }
    }

    // MARK: - Public initializer

    /// Initialises the Apple Pay button.
    /// 1. POSTs the config dict to `https://mw-sdk.beta.tap.company/v2/button/config`
    /// 2. Reads `redirect_url` from the response
    /// 3. Loads that URL into the WKWebView
    ///    (In the Simulator a native PKPaymentButton replaces the webView once onReady fires)
    internal func initApplePay(configDict: [String: Any], delegate: ApplePayDelegate? = nil) {
        self.delegate = delegate
        currentConfig = configDict

        DispatchQueue.main.async {
            self.showShimmer()
            #if targetEnvironment(simulator)
            self.simulatorPayButton?.removeFromSuperview()
            self.simulatorPayButton = nil
            #endif
        }

        // Build the POST body — ensure required top-level fields are present
        var body = configDict
        if body["paymentMethod"] == nil { body["paymentMethod"] = "applepay" }
        if body["platform"] == nil      { body["platform"] = "mobile" }

        UrlBasedUtils.fetchButtonConfig(body: body) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let redirectUrl):
                self.openUrl(url: redirectUrl)
            case .failure(let error):
                DispatchQueue.main.async {
                    self.hideShimmer()
                    self.delegate?.onError?(data: "{\"error\":\"\(error.localizedDescription)\"}")
                }
            }
        }
    }

    // MARK: - Simulator – native PKPaymentButton

    #if targetEnvironment(simulator)
    /// Tracks whether the user authorised payment (used to distinguish cancel vs success on sheet dismiss).
    internal var simulatorPaymentAuthorized = false

    /// Called after the button config loads.
    /// Swaps the hidden webView for a native PKPaymentButton so the Simulator
    /// shows a real Apple Pay button instead of a blank web surface.
    internal func showSimulatorNativeButton() {
        simulatorPayButton?.removeFromSuperview()
        simulatorPayButton = nil

        let iface  = currentConfig["interface"] as? [String: Any] ?? [:]
        let locale = (iface["locale"] as? String)?.lowercased() ?? "en"

        let button = PKPaymentButton(
            paymentButtonType: pkButtonType(from: currentConfig),
            paymentButtonStyle: pkButtonStyle(from: currentConfig)
        )
        button.cornerRadius             = pkCornerRadius(from: iface)
        button.semanticContentAttribute = locale == "ar" ? .forceRightToLeft : .forceLeftToRight
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(simulatorButtonTapped), for: .touchUpInside)
        containerView.addSubview(button)
        containerView.bringSubviewToFront(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: containerView.topAnchor),
            button.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
        simulatorPayButton = button
        containerView.setNeedsLayout()
        containerView.layoutIfNeeded()
    }

    /// Tapping the native button opens the real Apple Pay sheet.
    @objc private func simulatorButtonTapped() {
        delegate?.onClick?()

        let request = buildSimulatorPaymentRequest()
        guard PKPaymentAuthorizationViewController.canMakePayments(),
              let authVC = PKPaymentAuthorizationViewController(paymentRequest: request) else {
            delegate?.onError?(data: "{\"error\":\"Cannot present Apple Pay sheet on this device\"}")
            return
        }
        authVC.delegate = self
        simulatorPaymentAuthorized = false
        DispatchQueue.main.async {
            UIApplication.shared.topViewController()?.present(authVC, animated: true)
        }
    }

    // MARK: - PKPaymentRequest builder

    private func buildSimulatorPaymentRequest() -> PKPaymentRequest {
        let request = PKPaymentRequest()

        // Merchant identifier – prefer an explicit key in config, fall back to a derived value.
        // In the Simulator Apple Pay sheet shows regardless of the identifier.
        let merchantId = (currentConfig["merchant"] as? [String: Any])?["applePayMerchantId"] as? String
            ?? "merchant.\(TapApplicationPlistInfo.shared.bundleIdentifier ?? "com.tap.applepay")"
        request.merchantIdentifier    = merchantId
        request.merchantCapabilities  = .capability3DS
        request.supportedNetworks     = supportedNetworks(from: currentConfig)

        let transaction               = currentConfig["transaction"] as? [String: Any] ?? [:]
        request.currencyCode          = (transaction["currency"] as? String)?.uppercased() ?? "USD"
        request.countryCode           = countryCode(forCurrency: request.currencyCode)
        request.paymentSummaryItems   = paymentSummaryItems(from: transaction)
        return request
    }

    private func supportedNetworks(from config: [String: Any]) -> [PKPaymentNetwork] {
        let brands = (config["acceptance"] as? [String: Any])?["supportedBrands"] as? [String] ?? ["visa", "masterCard"]
        return brands.compactMap { brand in
            switch brand.lowercased() {
            case "visa":           return .visa
            case "mastercard":     return .masterCard
            case "amex":           return .amex
            case "discover":       return .discover
            case "jcb":            return .JCB
            case "chinaunionpay":  return .chinaUnionPay
            case "maestro":        return .maestro
            case "mada":           return .mada
            default:               return nil
            }
        }
    }

    private func paymentSummaryItems(from transaction: [String: Any]) -> [PKPaymentSummaryItem] {
        var items: [PKPaymentSummaryItem] = []

        // Line items
        if let rawItems = transaction["items"] as? [[String: Any]] {
            for item in rawItems {
                let label  = item["label"] as? String ?? "Item"
                let amount = NSDecimalNumber(string: item["amount"] as? String ?? "0")
                items.append(PKPaymentSummaryItem(label: label, amount: amount))
            }
        }

        // Total
        let totalAmount = NSDecimalNumber(string: transaction["amount"] as? String ?? "0")
        items.append(PKPaymentSummaryItem(label: "Total", amount: totalAmount, type: .final))
        return items
    }

    private func countryCode(forCurrency currency: String) -> String {
        switch currency.uppercased() {
        case "KWD": return "KW"
        case "SAR": return "SA"
        case "AED": return "AE"
        case "BHD": return "BH"
        case "QAR": return "QA"
        case "OMR": return "OM"
        case "JOD": return "JO"
        case "EGP": return "EG"
        case "USD": return "US"
        case "EUR": return "DE"
        case "GBP": return "GB"
        default:    return "US"
        }
    }

    private func pkButtonType(from config: [String: Any]) -> PKPaymentButtonType {
        let t = ((config["interface"] as? [String: Any])?["type"] as? String)?.lowercased() ?? ""
        switch t {
        case "book":                  return .book
        case "buy":                   return .buy
        case "check-out","checkout":  return .checkout
        case "subscribe":             return .subscribe
        case "donate":                return .donate
        case "set-up","setup":        return .setUp
        default:                      return .buy
        }
    }

    private func pkButtonStyle(from config: [String: Any]) -> PKPaymentButtonStyle {
        let theme = ((config["interface"] as? [String: Any])?["theme"] as? String)?.lowercased() ?? ""
        return theme == "dark" ? .black : .white
    }

    /// `"straight"` → 0 pt radius, `"curved"` (or anything else) → 10 pt radius.
    private func pkCornerRadius(from iface: [String: Any]) -> CGFloat {
        let edges = (iface["edges"] as? String)?.lowercased() ?? ""
        return edges == "straight" ? 0 : 10
    }
    #endif

    // MARK: - 3DS redirect support

    internal func showRedirectionView(for redirection: Redirection) {
        threeDsView = ThreeDSViewController()
        threeDsView?.isModalInPresentation = true
        threeDsView?.redirectUrl = tapApplePayRedirectionScheme
        threeDsView?.redirectionData = redirection
        threeDsView?.selectedLocale = currentLocale
        threeDsView?.onCanceled = {
            self.threeDsView?.dismiss(animated: true) { self.handleOnCancel() }
        }
        threeDsView?.onRedirectionReached = { redirectionUrl in
            self.threeDsView?.dismiss(animated: true) {
                DispatchQueue.main.async {
                    self.webView.evaluateJavaScript("window.retrieve('\(redirectionUrl)')")
                }
            }
        }
        threeDsView?.idleForWhile = {
            self.threeDsView?.idleForWhile = {}
            DispatchQueue.main.async {
                UIApplication.shared.topViewController()?.present(self.threeDsView!, animated: true)
            }
        }
        threeDsView?.startLoading()
    }

    internal func handleOnCancel() {
        delegate?.onCanceled?()
        webView.evaluateJavaScript("window.cancel()")
    }
}

// MARK: - PKPaymentAuthorizationViewControllerDelegate (Simulator only)

#if targetEnvironment(simulator)
extension ApplePayButton: PKPaymentAuthorizationViewControllerDelegate {

    func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
        simulatorPaymentAuthorized = true

        // Serialize the PKPayment token and surface it as onSuccess
        let tokenData   = payment.token.paymentData
        let tokenString = String(data: tokenData, encoding: .utf8) ?? "{}"
        delegate?.onSuccess?(data: tokenString)
    }

    func paymentAuthorizationViewControllerDidFinish(
        _ controller: PKPaymentAuthorizationViewController
    ) {
        controller.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            if !self.simulatorPaymentAuthorized {
                self.delegate?.onCanceled?()
            }
            self.simulatorPaymentAuthorized = false
        }
    }
}
#endif
