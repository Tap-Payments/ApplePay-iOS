import UIKit

/// The public entry point for displaying the Tap Apple Pay button.
/// Add this view to your layout and call `initApplePay(configDict:delegate:)` to start.
@objc public class ApplePayView: UIView {

    internal var delegate: ApplePayDelegate?
    internal var buttonView: ApplePayButton = .init()

    /// Retains the legacy adapter for its lifetime during the payment session.
    private var legacyAdapter: TapApplePayKitAdapter?

    /// Shimmer shown while the remote flag is being fetched (only visible on cache miss).
    private var shimmerView: TapShimmerView?

    // MARK: - Init

    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        // Warm up the remote flag cache as early as possible
        TapRemoteFlags.shared.prefetch()
    }

    // MARK: - Private layout

    private func attachButtonView() {
        buttonView.removeFromSuperview()
        buttonView = ApplePayButton()
        addSubview(buttonView)
        buttonView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonView.topAnchor.constraint(equalTo: topAnchor),
            buttonView.leadingAnchor.constraint(equalTo: leadingAnchor),
            buttonView.trailingAnchor.constraint(equalTo: trailingAnchor),
            buttonView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        buttonView.layoutIfNeeded()
        buttonView.updateConstraints()
        layoutIfNeeded()
    }

    private func showShimmer(configDict: [String: Any]) {
        shimmerView?.removeFromSuperview()
        let shimmer = TapShimmerView()
        shimmer.translatesAutoresizingMaskIntoConstraints = false
        if let iface = configDict["interface"] as? [String: Any] {
            shimmer.applyInterfaceConfig(iface)
        }
        addSubview(shimmer)
        NSLayoutConstraint.activate([
            shimmer.topAnchor.constraint(equalTo: topAnchor),
            shimmer.leadingAnchor.constraint(equalTo: leadingAnchor),
            shimmer.trailingAnchor.constraint(equalTo: trailingAnchor),
            shimmer.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        shimmerView = shimmer
    }

    private func hideShimmer() {
        shimmerView?.removeFromSuperview()
        shimmerView = nil
    }

    // MARK: - Public API

    /// Initialise and render the Apple Pay button.
    /// - Parameters:
    ///   - configDict: Configuration dictionary matching the Tap Apple Pay button config schema.
    ///   - delegate: Optional delegate to receive payment events.
    ///   - forceLegacy: When `true`, skips the Firebase flag entirely and directly uses the
    ///     native `TapApplePayKit-iOS` implementation. When `nil` (default), the remote Firebase
    ///     flag controls the path. Falls back to legacy if Firebase is unreachable.
    @objc public func initApplePay(configDict: [String: Any], delegate: ApplePayDelegate? = nil, forceLegacy: Bool = false) {
        // Tear down any previous implementation before starting fresh
        legacyAdapter = nil
        subviews.forEach { $0.removeFromSuperview() }

        // Skip Firebase entirely when the caller explicitly forces the legacy path
        if forceLegacy {
            applyImplementation(configDict: configDict, delegate: delegate, useLegacy: true)
            return
        }

        showShimmer(configDict: configDict)

        TapRemoteFlags.shared.fetchLegacyFlag { [weak self] remoteUseLegacy in
            guard let self else { return }
            self.hideShimmer()
            self.applyImplementation(configDict: configDict, delegate: delegate, useLegacy: remoteUseLegacy)
        }
    }

    // MARK: - Private implementation fork

    private func applyImplementation(configDict: [String: Any], delegate: ApplePayDelegate?, useLegacy: Bool) {
        if useLegacy {
            let adapter = TapApplePayKitAdapter()
            legacyAdapter = adapter
            adapter.initApplePay(configDict: configDict, delegate: delegate, parentView: self)
        } else {
            attachButtonView()
            buttonView.initApplePay(configDict: configDict, delegate: delegate)
        }
    }
}
