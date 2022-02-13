import Foundation
import CryptoKit

extension String {
    func sha256() -> String {
        SHA256.hash(data: Data(utf8)).compactMap { String(format: "%02x", $0) }.joined()
    }
}
