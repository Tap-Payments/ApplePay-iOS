import UIKit
import PassKit
@_implementationOnly import TapApplePayKit_iOS
@_implementationOnly import CommonDataModelsKit_iOS

/// Adapts the new `[String: Any]` config format into the legacy TapApplePayKit-iOS API,
/// mirroring the pattern from TapApplePayKit-Example/ViewController.swift:
///
///   tapApplePayButton.setup()
///   tapApplePayButton.dataSource = self   // provides TapApplePayRequest
///   tapApplePayButton.delegate   = self   // receives tapApplePayFinished / error / cancelled
///
/// Flow:
///   1. Parses config and calls `setupTapMerchantApplePay`.
///   2. On success, embeds `TapApplePayButton`, sets itself as dataSource + delegate, calls `setup()`.
///   3. Button handles authorization internally; delegate callbacks bridge to `ApplePayDelegate`.
internal class TapApplePayKitAdapter: NSObject {
    
    // MARK: - Properties
    
    private weak var applePayDelegate: ApplePayDelegate?
    private weak var parentView: UIView?
    private var tapApplePayButton: TapApplePayButton?
    private var builtRequest: TapApplePayRequest?
    
    // MARK: - Entry point
    
    func initApplePay(configDict: [String: Any], delegate: ApplePayDelegate?, parentView: UIView) {
        self.applePayDelegate = delegate
        self.parentView       = parentView
        
        guard let publicKey = configDict["publicKey"] as? String else {
            delegate?.onError?(data: "Legacy adapter: missing 'publicKey' in config")
            return
        }
        
        let merchantDict    = configDict["merchant"]    as? [String: Any] ?? [:]
        let transactionDict = configDict["transaction"] as? [String: Any] ?? [:]
        let acceptanceDict  = configDict["acceptance"]  as? [String: Any] ?? [:]
        let interfaceDict   = configDict["interface"]   as? [String: Any] ?? [:]
        
        let merchantID = merchantDict["id"] as? String ?? ""
        let applePayMerchantID = merchantDict["applePayMerchantId"] as? String
        ?? merchantDict["identifier"] as? String
        ?? ""
        
        let amount: Double = {
            if let d = transactionDict["amount"] as? Double { return d }
            if let s = transactionDict["amount"] as? String, let d = Double(s) { return d }
            return 1.0
        }()
        
        let currencyString = transactionDict["currency"] as? String ?? "USD"
        let currency       = TapCurrencyCode(appleRawValue: currencyString) ?? .USD
        let networks       = parseNetworks(from: acceptanceDict["supportedBrands"] as? [String] ?? [])
        let items          = parsePaymentItems(from: transactionDict["items"] as? [[String: Any]] ?? [])
        let buttonType     = getTapApplePayButtonType(type: interfaceDict["type"] as? String ?? "") ?? .BuyWithApplePay
        let buttonStyle    = themeToStyle(interfaceDict["theme"] as? String ?? "dark")
        let cornerRadius: CGFloat = {
            if let d = interfaceDict["cornerRadius"] as? Double { return CGFloat(d) }
            if let s = interfaceDict["cornerRadius"] as? String, let d = Double(s) { return CGFloat(d) }
            return 10
        }()
        
        let request = TapApplePayRequest()
        request.build(
            paymentNetworks: networks.isEmpty ? [.Visa, .MasterCard, .Amex] : networks,
            paymentItems: items,
            paymentAmount: amount,
            currencyCode: currency,
            applePayMerchantID: applePayMerchantID
        )
        builtRequest = request
        
        TapApplePay.setupTapMerchantApplePay(
            merchantKey: makeSecretKey(from: publicKey),
            merchantID: merchantID,
            onSuccess: { [weak self] in
                DispatchQueue.main.async {
                    self?.showButton(type: buttonType, style: buttonStyle, cornerRadius: cornerRadius)
                    self?.applePayDelegate?.onReady?()
                }
            },
            onErrorOccured: { [weak self] errorMessage in
                DispatchQueue.main.async {
                    self?.applePayDelegate?.onError?(data: errorMessage ?? "Legacy adapter: setup failed")
                }
            },
            tapApplePayRequest: request
        )
    }
    
    // MARK: - Button rendering (mirrors viewWillAppear in TapApplePayKit-Example)
    
    private func showButton(type: TapApplePayButtonType, style: TapApplePayButtonStyleOutline, cornerRadius: CGFloat = 10) {
        guard let parentView else { return }
        
        tapApplePayButton?.removeFromSuperview()
        
        let button = TapApplePayButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.dataSource = self
        button.delegate   = self
        tapApplePayButton = button
        
        parentView.addSubview(button)
        NSLayoutConstraint.activate([
            //            button.centerYAnchor.constraint(equalTo: parentView.centerYAnchor),
            button.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
            button.topAnchor.constraint(equalTo: parentView.topAnchor),
            
            //            button.heightAnchor.constraint(equalToConstant: 48),
        ])
        
        button.setup(buttonType: type, buttonStyle: style)
        button.cornerRadius = cornerRadius
    }
    
    // MARK: - Config parsing helpers
    
    private func parseNetworks(from brands: [String]) -> [TapApplePayPaymentNetwork] {
        brands.compactMap { TapApplePayPaymentNetwork(rawValue: $0) }
    }
    
    private func parsePaymentItems(from items: [[String: Any]]) -> [PKPaymentSummaryItem] {
        items.compactMap { item -> PKPaymentSummaryItem? in
            guard let label = item["label"] as? String else { return nil }
            let amount: Double = {
                if let d = item["amount"] as? Double { return d }
                if let s = item["amount"] as? String, let d = Double(s) { return d }
                return 0
            }()
            return PKPaymentSummaryItem(label: label, amount: NSDecimalNumber(value: amount))
        }
    }
    
    private func themeToStyle(_ theme: String) -> TapApplePayButtonStyleOutline {
        theme.lowercased() == "light" ? .White : .Black
    }
    
    private func makeSecretKey(from publicKey: String) -> SecretKey {
        if publicKey.hasPrefix("pk_live_") {
            TapApplePay.sdkMode = .production
            return SecretKey(sandbox: "", production: publicKey)
        } else {
            TapApplePay.sdkMode = .sandbox
            return SecretKey(sandbox: publicKey, production: "")
        }
    }
}

// MARK: - TapApplePayButtonDataSource (mirrors `var tapApplePayRequest` in the example)

extension TapApplePayKitAdapter: TapApplePayButtonDataSource {
    var tapApplePayRequest: TapApplePayRequest {
        return builtRequest ?? TapApplePayRequest()
    }
}

// MARK: - TapApplePayButtonDelegate (bridges to ApplePayDelegate)

extension TapApplePayKitAdapter: TapApplePayButtonDelegate {
    func tapApplePayFinished(with tapAppleToken: TapApplePayToken) {
        DispatchQueue.main.async { [weak self] in
            self?.applePayDelegate?.onSuccess?(data: tapAppleToken.stringAppleToken ?? "")
        }
    }
    
    func tapApplePayValidationError(error: TapApplePayRequestValidationError) {
        DispatchQueue.main.async { [weak self] in
            self?.applePayDelegate?.onError?(data: error.TapApplePayRequestValidationErrorRawValue())
        }
    }
    
    func tapApplePayCancelled() {
        DispatchQueue.main.async { [weak self] in
            self?.applePayDelegate?.onCanceled?()
        }
    }
}

extension TapApplePayKitAdapter {
    func getTapApplePayButtonType(type: String) -> TapApplePayButtonType {
        switch type {
            
        case "book":
            return TapApplePayButtonType.BookWithApplePay
            
        case "check-out":
            return TapApplePayButtonType.CheckoutWithApplePay
            
        case "plain":
            return TapApplePayButtonType.AppleLogoOnly
            
        case "subscribe":
            return TapApplePayButtonType.SubscribeWithApplePay
            
        case "pay":
            return TapApplePayButtonType.PayWithApplePay
            
        case "buy":
            return TapApplePayButtonType.BuyWithApplePay
            
        default:
            return TapApplePayButtonType.AppleLogoOnly
        }
    }
}
