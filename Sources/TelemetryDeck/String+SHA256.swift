import CryptoKit
import Foundation

extension String {
    func sha256() -> String {
        SHA256.hash(data: Data(utf8)).compactMap { String(format: "%02x", $0) }.joined()
    }
}
