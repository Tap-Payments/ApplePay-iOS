import UIKit

/// Shimmer loading overlay shown while the Apple Pay web SDK initialises.
///
/// Colors match the Card-iOS Lottie JSON loaders exactly:
/// - Light mode: background #f2f2f2, highlight #e9e9e9
/// - Dark  mode: background #6b6b6b, highlight #5f5f5f
///
/// The corner radius automatically mirrors the host view's `layer.cornerRadius`
/// so the shimmer perfectly covers the button at any edge style.
internal class TapShimmerView: UIView {

    // MARK: - Sublayers

    private let shimmerLayer = CAGradientLayer()

    // MARK: - Configuration overrides
    // When set these take priority over system trait values.

    /// `"dark"` or `"light"` — overrides the system appearance when set.
    internal var themeOverride: String? = nil {
        didSet { applyThemeColors() }
    }

    /// Explicit corner radius — overrides the superview-mirroring behaviour when set.
    internal var cornerRadiusOverride: CGFloat? = nil {
        didSet {
            if let r = cornerRadiusOverride {
                layer.cornerRadius        = r
                shimmerLayer.cornerRadius = r
            }
        }
    }

    /// Convenience: apply both `interface.theme` and `interface.edges` from the config dict in one call.
    internal func applyInterfaceConfig(_ iface: [String: Any]) {
        themeOverride        = (iface["theme"] as? String)?.lowercased()
        let edges            = (iface["edges"] as? String)?.lowercased() ?? ""
        cornerRadiusOverride = edges == "straight" ? 0 : 10
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Setup

    private func setup() {
        layer.masksToBounds = true
        isUserInteractionEnabled = false

        applyThemeColors()

        // Horizontal gradient band — starts fully off the left edge
        shimmerLayer.startPoint = CGPoint(x: 0, y: 0.5)
        shimmerLayer.endPoint   = CGPoint(x: 1, y: 0.5)
        shimmerLayer.locations  = [-1.0, -0.5, 0.0]
        layer.addSublayer(shimmerLayer)
    }

    // MARK: - Theme

    private func applyThemeColors() {
        // Use the explicit config theme when provided; otherwise fall back to the system appearance.
        let isDarkTheme = (themeOverride == "dark") || (themeOverride == nil && traitCollection.userInterfaceStyle == .dark)

        // Colors taken directly from the Lottie JSON gradient keyframes:
        // Light: rgb(0.949, 0.949, 0.949) = #f2f2f2  /  rgb(0.914, 0.914, 0.914) = #e9e9e9
        // Dark:  rgb(0.420, 0.420, 0.420) = #6b6b6b  /  rgb(0.373, 0.373, 0.373) = #5f5f5f
        let darkBaseColor = UIColor(red: 0.420, green: 0.420, blue: 0.420, alpha: 1)
        let lightBaseColor = UIColor(red: 0.949, green: 0.949, blue: 0.949, alpha: 1)
        let darkHighlightColor = UIColor(red: 0.373, green: 0.373, blue: 0.373, alpha: 1)
        let lightHighlightColor = UIColor(red: 0.914, green: 0.914, blue: 0.914, alpha: 1)

        let baseColor = lightBaseColor
        let highlightColor = lightHighlightColor

        backgroundColor = baseColor
        shimmerLayer.colors = [
            baseColor.cgColor,
            highlightColor.cgColor,
            baseColor.cgColor,
        ]
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        // Use the explicit override when set; otherwise mirror the superview's corner radius.
        if let r = cornerRadiusOverride {
            layer.cornerRadius        = r
            shimmerLayer.cornerRadius = r
        } else if let superRadius = superview?.layer.cornerRadius {
            layer.cornerRadius        = superRadius
            shimmerLayer.cornerRadius = superRadius
        }

        shimmerLayer.frame = bounds

        if shimmerLayer.animation(forKey: "shimmerSweep") == nil {
            startAnimating()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            applyThemeColors()
        }
    }

    // MARK: - Animation
    //
    // The Lottie JSON sweeps a 180 px wide band across a 358 px button in 21 frames @ 30 fps
    // = 0.7 s.  We replicate this with a CABasicAnimation on gradient locations.

    private func startAnimating() {
        let sweep = CABasicAnimation(keyPath: "locations")
        sweep.fromValue      = [-1.0, -0.5, 0.0]  // band starts off left edge
        sweep.toValue        = [1.0,  1.5,  2.0]  // band ends off right edge
        sweep.duration       = 0.7                // 21 frames @ 30 fps
        sweep.repeatCount    = .infinity
        sweep.timingFunction = CAMediaTimingFunction(name: .linear)
        shimmerLayer.add(sweep, forKey: "shimmerSweep")
    }

    // MARK: - Dismiss

    internal func hideAnimated() {
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
        }, completion: { _ in
            self.shimmerLayer.removeAllAnimations()
            self.removeFromSuperview()
        })
    }
}
