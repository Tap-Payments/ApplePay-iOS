import Foundation
import UIKit
import WebKit
import SharedDataModels_iOS

// MARK: - WKNavigationDelegate

extension ApplePayButton: WKNavigationDelegate {

    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        var policy: WKNavigationActionPolicy?
        defer { decisionHandler(policy ?? .allow) }
        print("URL:",navigationAction.request.url?.absoluteString ?? "no url")
        guard let url = navigationAction.request.url else { return }
        let urlString = url.absoluteString

        // Block the custom scheme from loading in the webview
        if urlString.hasPrefix(tapApplePayWebSdkScheme) { policy = .cancel }
        print(urlString)
        if urlString.contains(tapApplePayWebSdkScheme) {
            switch urlString {
            case _ where urlString.contains(CallBackSchemeEnum.onReady.rawValue):
                hideShimmer()
                #if targetEnvironment(simulator)
                showSimulatorNativeButton()
                #endif
                delegate?.onReady?()

            case _ where urlString.contains(CallBackSchemeEnum.onClick.rawValue):
                delegate?.onClick?()

            case _ where urlString.contains(CallBackSchemeEnum.onOrderCreated.rawValue):
                delegate?.onOrderCreated?(data: tap_extractDataFromUrl(url, for: "data", shouldBase64Decode: false))

            case _ where urlString.contains(CallBackSchemeEnum.onChargeCreated.rawValue):
                handleOnChargeCreated(data: tap_extractDataFromUrl(url, for: "data", shouldBase64Decode: true))

            case _ where urlString.contains(CallBackSchemeEnum.onMerchantValidation.rawValue):
                delegate?.onMerchantValidation?(data: tap_extractDataFromUrl(url, for: "data", shouldBase64Decode: true))

            case _ where urlString.contains(CallBackSchemeEnum.onSuccess.rawValue):
                delegate?.onSuccess?(data: tap_extractDataFromUrl(url, for: "data", shouldBase64Decode: true))

            case _ where urlString.contains(CallBackSchemeEnum.onError.rawValue):
                delegate?.onError?(data: tap_extractDataFromUrl(url, for: "data", shouldBase64Decode: true))

            case _ where urlString.contains(CallBackSchemeEnum.onCancel.rawValue):
                handleOnCancel()

            default:
                break
            }
        }
    }


    // MARK: - Charge created handler

    private func handleOnChargeCreated(data: String) {
        guard let redirection = try? Redirection(data),
              let _ = redirection.url,
              let chargeID = redirection.id else {
            delegate?.onError?(data: "Failed to start authentication process")
            return
        }
        delegate?.onChargeCreated?(data: chargeID)
        if !(redirection.stopRedirection ?? false) {
            showRedirectionView(for: redirection)
        }
    }
}

// MARK: - WKUIDelegate

extension ApplePayButton: WKUIDelegate {
    public func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        return nil
    }
}
