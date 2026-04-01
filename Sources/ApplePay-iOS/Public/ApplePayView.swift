import UIKit

/// The public entry point for displaying the Tap Apple Pay button.
/// Add this view to your layout and call `initApplePay(configDict:delegate:)` to start.
@objc public class ApplePayView: UIView {

    internal var delegate: ApplePayDelegate?
    internal var buttonView: ApplePayButton = .init()

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

    // MARK: - Public API

    /// Initialise and render the Apple Pay button.
    /// - Parameters:
    ///   - configDict: Configuration dictionary matching the Tap Apple Pay button config schema.
    ///   - delegate: Optional delegate to receive payment events.
    @objc public func initApplePay(configDict: [String: Any], delegate: ApplePayDelegate? = nil) {
        attachButtonView()
        buttonView.initApplePay(configDict: configDict, delegate: delegate)
    }
}
