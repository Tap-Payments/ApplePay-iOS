import UIKit
import WebKit
import SharedDataModels_iOS

/// A simple modal view controller for handling 3DS / post-charge redirect pages.
internal class ThreeDSViewController: UIViewController {

    var redirectionData: Redirection = .init()
    var redirectUrl: String?
    var selectedLocale: String = "en"
    var idleForWhile: () -> () = {}
    var onRedirectionReached: (String) -> () = { _ in }
    var onCanceled: () -> () = {}

    private var webView: WKWebView?
    private var closeButton: UIButton = .init(type: .system)
    private var timer: Timer?
    private let delayTime: TimeInterval = 1.0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        view.backgroundColor = .white
        setupWebView()
        setupCloseButton()
    }

    private func setupWebView() {
        let prefs = WKPreferences()
        prefs.javaScriptEnabled = true
        prefs.javaScriptCanOpenWindowsAutomatically = true
        let config = WKWebViewConfiguration()
        config.preferences = prefs
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.isOpaque = false
        wv.backgroundColor = .white
        wv.scrollView.backgroundColor = .clear
        wv.scrollView.bounces = false
        wv.navigationDelegate = self
        webView = wv
        view.addSubview(wv)
        wv.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            wv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            wv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            wv.topAnchor.constraint(equalTo: view.topAnchor, constant: 56),
            wv.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupCloseButton() {
        let isAr = selectedLocale.lowercased() == "ar"
        closeButton.setTitle(isAr ? "إغلاق" : "Close", for: .normal)
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        view.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    @objc private func didTapClose() {
        onCanceled()
    }

    // MARK: - Public

    func startLoading() {
        guard let urlString = redirectionData.url, let url = URL(string: urlString) else { return }
        webView?.load(URLRequest(url: url))
    }
}

// MARK: - WKNavigationDelegate

extension ThreeDSViewController: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if let requestURL = navigationAction.request.url,
           let redirectUrl = redirectUrl?.lowercased(),
           requestURL.absoluteString.lowercased().hasPrefix(redirectUrl) {
            onRedirectionReached(NSURL(string: requestURL.absoluteString)?.query ?? requestURL.absoluteString)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: delayTime, repeats: false) { [weak self] t in
            t.invalidate()
            self?.idleForWhile()
        }
    }
}
