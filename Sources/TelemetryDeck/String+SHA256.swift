import Foundation
import CryptoKit

extension String {
    func sha256() -> String {
        SHA256.hash(data: Data(utf8)).description
    }
}
