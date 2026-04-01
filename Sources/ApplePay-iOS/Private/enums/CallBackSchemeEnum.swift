import Foundation

/// All possible callback event names sent from the Apple Pay web SDK via URL scheme
internal enum CallBackSchemeEnum: String {
    case onReady
    case onClick
    case onSuccess
    case onError
    case onCancel
    case onOrderCreated
    case onChargeCreated
    case onClosePopup
    case onMerchantValidation
}
