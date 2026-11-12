import XCTest
import Foundation
import Security
@testable import LivetexCore

/// Обработчик challenge, который использует тот же `LivetexTrust.configure`, что и SDK,
/// но с явно переданными якорями — в тестах нет `Info.plist` приложения.
final class AnchorTrustDelegate: NSObject, URLSessionDelegate {
    private let anchors: [SecCertificate]

    init(anchors: [SecCertificate]) {
        self.anchors = anchors
    }

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        if LivetexTrust.configure(trust, anchors: anchors) {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

enum TestCertificates {
    static func der(at path: String) throws -> SecCertificate {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try XCTUnwrap(SecCertificateCreateWithData(nil, data as CFData))
    }
}
