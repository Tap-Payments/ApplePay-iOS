import Foundation

// MARK: - Button config API response

/// The response from POST https://mw-sdk.beta.tap.company/v2/button/config
internal struct ButtonConfigResponse: Codable {
    /// The URL to load in the WKWebView
    let redirectUrl: String?

    enum CodingKeys: String, CodingKey {
        case redirectUrl = "redirect_url"
    }
}

// MARK: - Network errors

internal enum ApplePayNetworkError: Error, LocalizedError {
    case invalidConfig
    case networkError(Error)
    case invalidResponse
    case missingRedirectUrl(String)

    var errorDescription: String? {
        switch self {
        case .invalidConfig:       return "Invalid configuration — could not serialize to JSON"
        case .networkError(let e): return e.localizedDescription
        case .invalidResponse:     return "Unexpected response from button config API"
        case .missingRedirectUrl(let body): return "Missing redirect_url in response: \(body)"
        }
    }
}

// MARK: - Redirection model (used for 3DS redirect after charge creation)

internal struct Redirection: Codable {
    var url: String?
    var id: String?
    var powered: Bool?
    var stopRedirection: Bool?
}

extension Redirection {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Redirection.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }
}

func newJSONDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    if #available(iOS 10.0, OSX 10.12, *) {
        decoder.dateDecodingStrategy = .iso8601
    }
    return decoder
}

func newJSONEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    if #available(iOS 10.0, OSX 10.12, *) {
        encoder.dateEncodingStrategy = .iso8601
    }
    return encoder
}
