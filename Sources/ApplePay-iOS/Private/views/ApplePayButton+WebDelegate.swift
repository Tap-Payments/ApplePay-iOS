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

    // MARK: - Simulator fallback

    #if targetEnvironment(simulator)
    /// Primary fallback: page finished loading but web SDK never fired `onReady`.
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard simulatorPayButton == nil else { return }
        hideShimmer()
        showSimulatorNativeButton()
        delegate?.onReady?()
    }

    /// Secondary fallback: page failed mid-load — still show the native button.
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        guard simulatorPayButton == nil else { return }
        hideShimmer()
        showSimulatorNativeButton()
        delegate?.onReady?()
    }

    /// Secondary fallback: provisional navigation failed (DNS, SSL, network) — still show native button.
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        guard simulatorPayButton == nil else { return }
        hideShimmer()
        showSimulatorNativeButton()
        delegate?.onReady?()
    }
    #endif

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
