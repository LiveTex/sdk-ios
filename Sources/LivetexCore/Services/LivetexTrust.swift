import Foundation
import Security

public enum LivetexTrust {

    public static var isEnabled: Bool {
        return !anchors.isEmpty
    }

    public static var session: URLSession {
        return isEnabled ? trustedSession : URLSession.shared
    }

    public static func handle(_ challenge: URLAuthenticationChallenge,
                              completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard isEnabled,
              challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let isTrusted = configure(trust, anchors: anchors)

        if isTrusted {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    /// Добавляет переданные якоря к системным и проверяет цепочку.
    static func configure(_ trust: SecTrust, anchors: [SecCertificate]) -> Bool {
        let anchorsStatus = SecTrustSetAnchorCertificates(trust, anchors as CFArray)
        let onlyAnchorsStatus = SecTrustSetAnchorCertificatesOnly(trust, false)
        return anchorsStatus == errSecSuccess && onlyAnchorsStatus == errSecSuccess && evaluate(trust)
    }

    private static let certificateInfoKey = "LivetexRootCertificate"

    private static let trustedSession = URLSession(configuration: .default,
                                                   delegate: LivetexTrustSessionDelegate(),
                                                   delegateQueue: nil)

    private static let anchors: [SecCertificate] = loadAnchors()

    private static func evaluate(_ trust: SecTrust) -> Bool {
        guard #available(iOS 12.0, macOS 10.14, tvOS 12.0, watchOS 5.0, *) else {
            return false
        }
        var error: CFError?
        return SecTrustEvaluateWithError(trust, &error)
    }

    private static func loadAnchors() -> [SecCertificate] {
        guard let info = Bundle.main.infoDictionary?["Livetex"] as? [String: String],
              let resource = info[certificateInfoKey],
              let url = certificateURL(for: resource),
              let data = try? Data(contentsOf: url) else {
            return []
        }
        return certificates(from: data)
    }

    private static func certificateURL(for resource: String) -> URL? {
        if let url = Bundle.main.url(forResource: resource, withExtension: nil) {
            return url
        }
        let name = (resource as NSString).deletingPathExtension
        let ext = (resource as NSString).pathExtension
        guard !ext.isEmpty else { return nil }
        return Bundle.main.url(forResource: name, withExtension: ext)
    }

    static func certificates(from data: Data) -> [SecCertificate] {
        if let text = String(data: data, encoding: .utf8), text.contains("-----BEGIN CERTIFICATE-----") {
            return pemBlocks(from: text).compactMap { SecCertificateCreateWithData(nil, $0 as CFData) }
        }
        return [SecCertificateCreateWithData(nil, data as CFData)].compactMap { $0 }
    }

    static func pemBlocks(from text: String) -> [Data] {
        var blocks: [Data] = []
        var body: String?
        for line in text.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.contains("-----BEGIN CERTIFICATE-----") {
                body = ""
            } else if trimmed.contains("-----END CERTIFICATE-----") {
                if let body = body, let data = Data(base64Encoded: body) {
                    blocks.append(data)
                }
                body = nil
            } else if body != nil {
                body?.append(trimmed)
            }
        }
        return blocks
    }
}

private final class LivetexTrustSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        LivetexTrust.handle(challenge, completionHandler: completionHandler)
    }
}
