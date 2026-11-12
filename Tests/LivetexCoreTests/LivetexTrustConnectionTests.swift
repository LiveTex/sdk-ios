import XCTest
import Security
@testable import LivetexCore

/// Проверяет не разбор сертификатов, а само соединение: поднимает локальный TLS-сервер
/// с собственным УЦ и ходит на него HTTPS-сессией.
final class LivetexTrustConnectionTests: XCTestCase {

    private var server: TLSTestServer!

    override func setUpWithError() throws {
        server = try TLSTestServer()
        try server.start()
    }

    override func tearDown() {
        server.stop()
        server = nil
    }

    /// Корень УЦ передан в доверие — соединение проходит.
    func testConnectionSucceedsWithTrustedAnchor() throws {
        let session = URLSession(configuration: .ephemeral,
                                 delegate: AnchorTrustDelegate(anchors: [server.rootCertificate]),
                                 delegateQueue: nil)
        defer { session.invalidateAndCancel() }

        let result = try request(session)

        XCTAssertEqual(result.statusCode, 200)
        XCTAssertFalse(result.body.isEmpty)
    }

    /// Без своего корня системное доверие не срабатывает: проверка сертификата не отключена.
    func testConnectionFailsWithoutAnchor() throws {
        let session = URLSession(configuration: .ephemeral)
        defer { session.invalidateAndCancel() }

        XCTAssertThrowsError(try request(session)) { error in
            XCTAssertEqual((error as NSError).code, NSURLErrorServerCertificateUntrusted)
        }
    }

    /// Чужой корень не делает соединение доверенным.
    func testConnectionFailsWithForeignAnchor() throws {
        let certificate = try XCTUnwrap(
            SecCertificateCreateWithData(nil, try XCTUnwrap(Data(base64Encoded: Self.foreignCertificateBase64)) as CFData)
        )
        let session = URLSession(configuration: .ephemeral,
                                 delegate: AnchorTrustDelegate(anchors: [certificate]),
                                 delegateQueue: nil)
        defer { session.invalidateAndCancel() }

        XCTAssertThrowsError(try request(session)) { error in
            // Свой challenge handler отклоняет соединение — так же, как LivetexTrust.handle в SDK.
            XCTAssertEqual((error as NSError).code, NSURLErrorCancelled)
        }
    }

    // MARK: - Helpers

    private func request(_ session: URLSession) throws -> (statusCode: Int, body: String) {
        let url = try XCTUnwrap(URL(string: "https://127.0.0.1:\(server.port)/"))
        let done = expectation(description: "response")
        var result: Result<(Int, String), Error>?

        session.dataTask(with: url) { data, response, error in
            if let error = error {
                result = .failure(error)
            } else if let http = response as? HTTPURLResponse, let data = data {
                result = .success((http.statusCode, String(data: data, encoding: .utf8) ?? ""))
            } else {
                result = .failure(URLError(.badServerResponse))
            }
            done.fulfill()
        }.resume()

        wait(for: [done], timeout: 15)
        let value = try XCTUnwrap(result)
        return try value.get()
    }

    /// Посторонний самоподписанный сертификат, CN=livetex-test-ca.
    private static let foreignCertificateBase64 = "MIICsDCCAZgCCQCGhQf4KfSxnjANBgkqhkiG9w0BAQsFADAaMRgwFgYDVQQDDA9saXZldGV4LXRlc3QtY2EwHhcNMjYxMTEyMTI1MDQ3WhcNMzYxMTA5MTI1MDQ3WjAaMRgwFgYDVQQDDA9saXZldGV4LXRlc3QtY2EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDIEsdmZmnngmFwW7JyHQF3GZEmpG3pfdFH8Vo6D7+Pq9bNrhAcRv4e/+KxwnoBGUPxObbIoANjm5KMtlE8XoKnep9Q2FSB2P0rt1dlEseJ3WW+2fxgtamMoTeXUSee8O0zKiF7rc8vDJ730RnZfHqWjXqL9r/5vQJsLFvVZZgsnsFmmx24sMo4NOYK8+ZYQfbyepmcBjPQO2Uh/EJAC+Vj5A1zOh6Vm4CLlLWEk/aZ+9ZWNc9xRsN+jhWs9B/hvtmtyG1zE+02ZH4S6aFpgU86cq6JpPDvROz1n8J9Am/bK+g89FGp4b7yrWktVyGaY7k2f6D2aWrf4GqGlvzQBzB3AgMBAAEwDQYJKoZIhvcNAQELBQADggEBAB/UDZISeBrYdTdX/rqjGZL9zgyy2Mi5tTZLGkwrzzIct6I2tOk9r71bvH6V3ieJbm8XQMxhadAzBi7K+xNU3kIJQXTpVph1vP04Su8HVajxZrkpzmzYhEsIFHIqaRl4sqTcQFm1joBDh24ApzmYS0lkp46ux9o2NoR52YlduZ5/RxnDPbldZ1AEr6rPpRu28XU9V0ziHmGLSMHkBMX8JPUI/+K74z9dskhSSMX7JPUax2k9CnIaBRHrU9k7xC+YJpKVxZA94x25PRTlS5PRQfrFPZTXk2pD3pRjFKl18VWJCFHSGNEgStHQMQymBm+XdH5+2NbkbrsDfzLMOGJOskk="
}

/// Локальный HTTPS-сервер: на лету генерирует УЦ и лист для `localhost`, поднимает
/// `openssl s_server` на свободном порту.
private final class TLSTestServer {
    private(set) var port: UInt16 = 0
    private(set) var rootCertificate: SecCertificate!

    private let directory: URL
    private var process: Process?

    init() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("livetex-tls-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func start() throws {
        let openSSL = "/usr/bin/openssl"
        let rootKey = path("root.key")
        let rootPem = path("root.pem")
        let leafKey = path("leaf.key")
        let leafCSR = path("leaf.csr")
        let leafPem = path("leaf.pem")
        let rootDer = path("root.der")

        try write("""
        [req]
        distinguished_name = dn
        prompt = no
        x509_extensions = v3
        [dn]
        CN = livetex-test-root
        [v3]
        basicConstraints = critical,CA:TRUE
        keyUsage = critical,keyCertSign,cRLSign
        """, to: path("root.cnf"))

        try write("""
        [req]
        distinguished_name = dn
        prompt = no
        [dn]
        CN = localhost
        """, to: path("leaf-req.cnf"))

        try write("""
        subjectAltName = DNS:localhost,IP:127.0.0.1
        extendedKeyUsage = serverAuth
        basicConstraints = critical,CA:FALSE
        keyUsage = critical,digitalSignature,keyEncipherment
        """, to: path("leaf-ext.cnf"))

        try run(openSSL, ["req", "-x509", "-newkey", "rsa:2048", "-nodes",
                          "-keyout", rootKey, "-out", rootPem, "-days", "3650",
                          "-config", path("root.cnf")])
        try run(openSSL, ["req", "-newkey", "rsa:2048", "-nodes",
                          "-keyout", leafKey, "-out", leafCSR,
                          "-config", path("leaf-req.cnf")])
        try run(openSSL, ["x509", "-req", "-in", leafCSR, "-CA", rootPem, "-CAkey", rootKey,
                          "-CAcreateserial", "-out", leafPem, "-days", "397",
                          "-extfile", path("leaf-ext.cnf")])
        try run(openSSL, ["x509", "-in", rootPem, "-outform", "DER", "-out", rootDer])

        let der = try Data(contentsOf: URL(fileURLWithPath: rootDer))
        rootCertificate = try XCTUnwrap(SecCertificateCreateWithData(nil, der as CFData))

        port = try Self.freePort()

        let process = Process()
        process.executableURL = URL(fileURLWithPath: openSSL)
        process.arguments = ["s_server", "-accept", "\(port)",
                             "-cert", leafPem, "-key", leafKey, "-www", "-quiet"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        self.process = process

        try waitUntilListening()
    }

    func stop() {
        process?.terminate()
        process?.waitUntilExit()
        process = nil
        try? FileManager.default.removeItem(at: directory)
    }

    // MARK: - Helpers

    private func path(_ name: String) -> String {
        directory.appendingPathComponent(name).path
    }

    private func write(_ text: String, to path: String) throws {
        try text.write(toFile: path, atomically: true, encoding: .utf8)
    }

    @discardableResult
    private func run(_ executable: String, _ arguments: [String]) throws -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            throw URLError(.cannotConnectToHost)
        }
        return process.terminationStatus
    }

    private func waitUntilListening() throws {
        for _ in 0..<100 {
            if isListening() {
                return
            }
            Thread.sleep(forTimeInterval: 0.05)
        }
        throw URLError(.cannotConnectToHost)
    }

    private func isListening() -> Bool {
        let socketFD = socket(AF_INET, SOCK_STREAM, 0)
        guard socketFD >= 0 else { return false }
        defer { close(socketFD) }

        var address = sockaddr_in()
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = port.bigEndian
        address.sin_addr.s_addr = inet_addr("127.0.0.1")

        let result = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(socketFD, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        return result == 0
    }

    private static func freePort() throws -> UInt16 {
        let socketFD = socket(AF_INET, SOCK_STREAM, 0)
        guard socketFD >= 0 else { throw URLError(.cannotConnectToHost) }
        defer { close(socketFD) }

        var address = sockaddr_in()
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = 0
        address.sin_addr.s_addr = inet_addr("127.0.0.1")

        let bindResult = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(socketFD, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bindResult == 0 else { throw URLError(.cannotConnectToHost) }

        var result = sockaddr_in()
        var length = socklen_t(MemoryLayout<sockaddr_in>.size)
        let nameResult = withUnsafeMutablePointer(to: &result) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                getsockname(socketFD, $0, &length)
            }
        }
        guard nameResult == 0 else { throw URLError(.cannotConnectToHost) }
        return result.sin_port.bigEndian
    }
}
