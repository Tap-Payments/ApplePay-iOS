import Foundation
import SwiftyRSA

/// Handles RSA-PKCS1 encryption of application header values.
internal class Crypter {
    static func encrypt(_ string: String, using key: String) -> String? {
        guard let publicKey = try? PublicKey(pemEncoded: key) else { return nil }
        guard let clear = try? ClearMessage(string: string, using: .utf8) else { return nil }
        var resultString = ""
        while true {
            guard let encrypted = try? clear.encrypted(with: publicKey, padding: .PKCS1) else { return nil }
            resultString = encrypted.base64String
            if !resultString.hasSuffix("AA==") { break }
        }
        return resultString
    }
}
