import Foundation

/// A protocol to allow listening to events and callbacks coming from the Apple Pay button
@objc public protocol ApplePayDelegate {
    /// Fired when the Apple Pay button is rendered and ready
    @objc optional func onReady()
    /// Fired when the customer taps the Apple Pay button
    @objc optional func onClick()
    /// Fired when the customer cancels the payment
    @objc optional func onCanceled()
    /// Fired when there is a connectivity or API error
    /// - Parameter data: JSON string describing the error
    @objc optional func onError(data: String)
    /// Fired when the payment succeeds
    /// - Parameter data: JSON string of the charge details
    @objc optional func onSuccess(data: String)
    /// Fired when an order is created
    /// - Parameter data: Order id string
    @objc optional func onOrderCreated(data: String)
    /// Fired when a charge is created
    /// - Parameter data: JSON string of the charge model
    @objc optional func onChargeCreated(data: String)
    /// Fired when Apple Pay requests merchant validation
    /// - Parameter data: JSON string containing the validation URL and session details
    @objc optional func onMerchantValidation(data: String)
}
