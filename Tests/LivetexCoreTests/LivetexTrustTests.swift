import XCTest
import Security
@testable import LivetexCore

final class LivetexTrustTests: XCTestCase {

    /// Самоподписанный сертификат для теста, CN=livetex-test-ca.
    private let testCertificateBase64 = "MIICsDCCAZgCCQCGhQf4KfSxnjANBgkqhkiG9w0BAQsFADAaMRgwFgYDVQQDDA9saXZldGV4LXRlc3QtY2EwHhcNMjYxMTEyMTI1MDQ3WhcNMzYxMTA5MTI1MDQ3WjAaMRgwFgYDVQQDDA9saXZldGV4LXRlc3QtY2EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDIEsdmZmnngmFwW7JyHQF3GZEmpG3pfdFH8Vo6D7+Pq9bNrhAcRv4e/+KxwnoBGUPxObbIoANjm5KMtlE8XoKnep9Q2FSB2P0rt1dlEseJ3WW+2fxgtamMoTeXUSee8O0zKiF7rc8vDJ730RnZfHqWjXqL9r/5vQJsLFvVZZgsnsFmmx24sMo4NOYK8+ZYQfbyepmcBjPQO2Uh/EJAC+Vj5A1zOh6Vm4CLlLWEk/aZ+9ZWNc9xRsN+jhWs9B/hvtmtyG1zE+02ZH4S6aFpgU86cq6JpPDvROz1n8J9Am/bK+g89FGp4b7yrWktVyGaY7k2f6D2aWrf4GqGlvzQBzB3AgMBAAEwDQYJKoZIhvcNAQELBQADggEBAB/UDZISeBrYdTdX/rqjGZL9zgyy2Mi5tTZLGkwrzzIct6I2tOk9r71bvH6V3ieJbm8XQMxhadAzBi7K+xNU3kIJQXTpVph1vP04Su8HVajxZrkpzmzYhEsIFHIqaRl4sqTcQFm1joBDh24ApzmYS0lkp46ux9o2NoR52YlduZ5/RxnDPbldZ1AEr6rPpRu28XU9V0ziHmGLSMHkBMX8JPUI/+K74z9dskhSSMX7JPUax2k9CnIaBRHrU9k7xC+YJpKVxZA94x25PRTlS5PRQfrFPZTXk2pD3pRjFKl18VWJCFHSGNEgStHQMQymBm+XdH5+2NbkbrsDfzLMOGJOskk="

    // MARK: - Конфигурация

    func testDisabledWithoutCertificateInInfoPlist() {
        XCTAssertFalse(LivetexTrust.isEnabled)
        XCTAssertTrue(LivetexTrust.session === URLSession.shared)
    }

    // MARK: - Разбор сертификатов

    func testParsesSingleDERCertificate() throws {
        let der = try XCTUnwrap(Data(base64Encoded: testCertificateBase64))
        XCTAssertEqual(LivetexTrust.certificates(from: der).count, 1)
    }

    func testParsesPEMChain() throws {
        let der = try XCTUnwrap(Data(base64Encoded: testCertificateBase64))
        let block = "-----BEGIN CERTIFICATE-----\n\(der.base64EncodedString())\n-----END CERTIFICATE-----\n"
        let chain = block + block

        XCTAssertEqual(LivetexTrust.pemBlocks(from: chain).count, 2)
        XCTAssertEqual(LivetexTrust.certificates(from: Data(chain.utf8)).count, 2)
    }

    func testGarbageIsNotParsedAsCertificate() {
        XCTAssertTrue(LivetexTrust.certificates(from: Data("not a certificate".utf8)).isEmpty)
    }

    // MARK: - Проверка цепочки

    func testTrustAcceptsChainWithOwnAnchor() throws {
        let certificate = try testCertificate()
        let trust = try makeTrust(certificate)

        XCTAssertTrue(LivetexTrust.configure(trust, anchors: [certificate]))
    }

    /// Системное хранилище не доверяет тестовому самоподписанному сертификату,
    /// значит проверка не отключена и чужой корень не проходит.
    func testTrustRejectsChainWithoutMatchingAnchor() throws {
        let certificate = try testCertificate()
        let trust = try makeTrust(certificate)

        XCTAssertFalse(LivetexTrust.configure(trust, anchors: []))
    }

    // MARK: - Helpers

    private func testCertificate() throws -> SecCertificate {
        let der = try XCTUnwrap(Data(base64Encoded: testCertificateBase64))
        return try XCTUnwrap(SecCertificateCreateWithData(nil, der as CFData))
    }

    private func makeTrust(_ certificate: SecCertificate) throws -> SecTrust {
        var trust: SecTrust?
        let status = SecTrustCreateWithCertificates([certificate] as CFArray,
                                                   SecPolicyCreateBasicX509(),
                                                   &trust)
        XCTAssertEqual(status, errSecSuccess)
        return try XCTUnwrap(trust)
    }
}
