import XCTest
@testable import LivetexCore

/// Контрактные проверки против поднятого стенда (см. stand/ в задаче OPT-6578).
/// Запускаются только если заданы `LIVETEX_STAND_PORT` и `LIVETEX_STAND_CA` (DER-корень стенда),
/// иначе скипаются — обычный `swift test` остаётся самодостаточным.
final class LivetexStandContractTests: XCTestCase {

    private var port: Int {
        Int(ProcessInfo.processInfo.environment["LIVETEX_STAND_PORT"] ?? "") ?? 0
    }

    private var caPath: String {
        ProcessInfo.processInfo.environment["LIVETEX_STAND_CA"] ?? ""
    }

    /// Ответ стенда на /v1/auth разбирается в модель SDK.
    func testAuthResponseDecodesIntoSessionToken() throws {
        let session = try makeSession()
        let token: SessionToken = try load(session, request: URLRequest(url: try url("/v1/auth")))

        XCTAssertFalse(token.visitorToken.isEmpty)
        XCTAssertTrue(token.endpoints.ws.hasPrefix("wss://"))
        XCTAssertTrue(token.endpoints.upload.hasPrefix("https://"))
    }

    /// Ответ стенда на /v1/upload разбирается в модель SDK.
    func testUploadResponseDecodesIntoAttachment() throws {
        let session = try makeSession()
        var request = URLRequest(url: try url("/v1/upload"))
        request.httpMethod = "POST"
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data("stand".utf8)

        let attachment: MessageAttachment = try load(session, request: request)

        XCTAssertFalse(attachment.name.isEmpty)
        XCTAssertTrue(attachment.url.hasPrefix("https://"))
    }

    // MARK: - Helpers

    private func makeSession() throws -> URLSession {
        try XCTSkipIf(port == 0 || caPath.isEmpty,
                      "стенд не запущен: нужны LIVETEX_STAND_PORT и LIVETEX_STAND_CA")
        let certificate = try TestCertificates.der(at: caPath)
        return URLSession(configuration: .ephemeral,
                          delegate: AnchorTrustDelegate(anchors: [certificate]),
                          delegateQueue: nil)
    }

    private func url(_ path: String) throws -> URL {
        try XCTUnwrap(URL(string: "https://localhost:\(port)\(path)"))
    }

    private func load<T: Decodable>(_ session: URLSession, request: URLRequest) throws -> T {
        let done = expectation(description: "response")
        var result: Result<T, Error>?

        session.dataTask(with: request) { data, _, error in
            if let error = error {
                result = .failure(error)
            } else {
                do {
                    result = .success(try JSONDecoder().decode(T.self, from: data ?? Data()))
                } catch {
                    result = .failure(error)
                }
            }
            done.fulfill()
        }.resume()

        wait(for: [done], timeout: 15)
        return try XCTUnwrap(result).get()
    }
}
