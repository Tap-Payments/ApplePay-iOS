import Foundation
import UIKit
import CoreTelephony
import SharedDataModels_iOS

// MARK: - Endpoints & schemes

/// POST endpoint: send the Apple Pay config body, receive back { "redirect_url": "..." }
internal let tapApplePayConfigEndpoint = "https://mw-sdk.beta.tap.company/v2/button/config"

/// Custom URL scheme the Apple Pay web SDK uses to send event callbacks to native
internal let tapApplePayWebSdkScheme = "tapapplepaywebsdk://"

/// Custom URL scheme injected as the return URL for 3DS/redirect flows
internal let tapApplePayRedirectionScheme = "tapapplepayredirectionwebsdk://"

// MARK: - Network layer

internal class UrlBasedUtils {

    // MARK: - Button config POST

    /// POSTs `body` (the Apple Pay config dict) to the Tap button config API and returns the
    /// `redirect_url` the server sends back.
    /// - Parameters:
    ///   - body: The full config dictionary (paymentMethod, merchant, transaction, customer …)
    ///   - completion: Called on a background thread; passes `.success(URL)` or `.failure(Error)`.
    static func fetchButtonConfig(
        body: [String: Any],
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        guard let endpoint = URL(string: tapApplePayConfigEndpoint),
              let bodyData = try? JSONSerialization.data(withJSONObject: body) else {
            completion(.failure(ApplePayNetworkError.invalidConfig))
            return
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Identify the calling app (mirrors Card-iOS's referer header)
        request.setValue(
            TapApplicationPlistInfo.shared.bundleIdentifier ?? "",
            forHTTPHeaderField: "referer"
        )
        request.httpBody = bodyData
        request.timeoutInterval = 30

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(ApplePayNetworkError.networkError(error)))
                return
            }

            guard let data = data else {
                completion(.failure(ApplePayNetworkError.invalidResponse))
                return
            }

            // Parse { "redirect_url": "..." }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let urlString = json["redirect_url"] as? String,
               let url = URL(string: urlString) {
                completion(.success(url))
                return
            }

            let body = String(data: data, encoding: .utf8) ?? "<empty>"
            completion(.failure(ApplePayNetworkError.missingRedirectUrl(body)))
        }.resume()
    }

    // MARK: - Application headers (sent as HTTP headers on the POST request for analytics)

    static func applicationHeaders(for publicKey: String) -> [String: String] {
        let encKey = headersEncryptionKey(for: publicKey)
        return [
            "application": applicationHeaderValue(key: encKey),
            "mdn":         Crypter.encrypt(TapApplicationPlistInfo.shared.bundleIdentifier ?? "", using: encKey) ?? "",
        ]
    }

    // MARK: - Headers encryption key selection

    static func headersEncryptionKey(for publicKey: String) -> String {
        return publicKey.contains("test") ? Constants.sandboxEncryptionKey : Constants.productionEncryptionKey
    }

    // MARK: - Private header builders

    private static func applicationHeaderValue(key: String) -> String {
        var details = applicationStaticDetails(key: key)
        details[Constants.HTTPHeaderValueKey.appLocale] = "en"
        return details.map { "\($0.key)=\($0.value)" }.joined(separator: "|")
    }

    static func applicationStaticDetails(key: String) -> [String: String] {
        let bundleID = TapApplicationPlistInfo.shared.bundleIdentifier ?? ""
        let sdkPlistInfo = TapBundlePlistInfo(bundle: Bundle(for: ApplePayButton.self))
        let requirerVersion = sdkPlistInfo.shortVersionString ?? "1.0.0"
        let networkInfo = CTTelephonyNetworkInfo()
        let providers = networkInfo.serviceSubscriberCellularProviders
        let osName = UIDevice.current.systemName
        let osVersion = UIDevice.current.systemVersion
        let deviceName = UIDevice.current.name
        let deviceNameFiltered = deviceName.tap_byRemovingAllCharactersExcept(
            "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ123456789"
        )
        let deviceType = UIDevice.current.model
        let deviceModel = UIDevice.current.localizedModel
        var simNetworkName: String = ""
        var simCountryISO: String = ""
        if let carrier = providers?.values.first {
            simNetworkName = carrier.carrierName ?? ""
            simCountryISO  = carrier.isoCountryCode ?? ""
        }
        return [
            Constants.HTTPHeaderValueKey.appID:                  Crypter.encrypt(bundleID, using: key) ?? "",
            Constants.HTTPHeaderValueKey.requirer:               Crypter.encrypt(Constants.HTTPHeaderValueKey.requirerValue, using: key) ?? "",
            Constants.HTTPHeaderValueKey.requirerVersion:        Crypter.encrypt(requirerVersion, using: key) ?? "",
            Constants.HTTPHeaderValueKey.requirerOS:             Crypter.encrypt(osName, using: key) ?? "",
            Constants.HTTPHeaderValueKey.requirerOSVersion:      Crypter.encrypt(osVersion, using: key) ?? "",
            Constants.HTTPHeaderValueKey.requirerDeviceName:     Crypter.encrypt(deviceNameFiltered, using: key) ?? "",
            Constants.HTTPHeaderValueKey.requirerDeviceType:     Crypter.encrypt(deviceType, using: key) ?? "",
            Constants.HTTPHeaderValueKey.requirerDeviceModel:    Crypter.encrypt(deviceModel, using: key) ?? "",
            Constants.HTTPHeaderValueKey.requirerSimNetworkName: Crypter.encrypt(simNetworkName, using: key) ?? "",
            Constants.HTTPHeaderValueKey.requirerSimCountryIso:  Crypter.encrypt(simCountryISO, using: key) ?? "",
        ]
    }

    // MARK: - Constants

    struct Constants {
        // RSA public keys for encrypting application identification headers
        static let sandboxEncryptionKey = """
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC8AX++RtxPZFtns4XzXFlDIxPB
h0umN4qRXZaKDIlb6a3MknaB7psJWmf2l+e4Cfh9b5tey/+rZqpQ065eXTZfGCAu
BLt+fYLQBhLfjRpk8S6hlIzc1Kdjg65uqzMwcTd0p7I4KLwHk1I0oXzuEu53fU1L
SZhWp4Mnd6wjVgXAsQIDAQAB
-----END PUBLIC KEY-----
"""
        static let productionEncryptionKey = """
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC9hSRms7Ir1HmzdZxGXFYgmpi3
ez7VBFje0f8wwrxYS9oVoBtN4iAt0DOs3DbeuqtueI31wtpFVUMGg8W7R0SbtkZd
GzszQNqt/wyqxpDC9q+97XdXwkWQFA72s76ud7eMXQlsWKsvgwhY+Ywzt0KlpNC3
Hj+N6UWFOYK98Xi+sQIDAQAB
-----END PUBLIC KEY-----
"""
        struct HTTPHeaderKey {
            static let application = "application"
            static let mdn = "mdn"
        }
        struct HTTPHeaderValueKey {
            static let appID                  = "cu"
            static let appLocale              = "al"
            static let requirer               = "aid"
            static let requirerOS             = "ro"
            static let requirerOSVersion      = "rov"
            static let requirerValue          = "iOS-checkout-sdk"
            static let requirerVersion        = "av"
            static let requirerDeviceName     = "rn"
            static let requirerDeviceType     = "rt"
            static let requirerDeviceModel    = "rm"
            static let requirerSimNetworkName = "rsn"
            static let requirerSimCountryIso  = "rsc"
        }
    }
}

// MARK: - Encodable helper

internal extension Encodable {
    var dictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? [String: Any]
    }
}

