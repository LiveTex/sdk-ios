//
//  LivetexSessionService.swift
//  LivetexMessaging
//
//  Created by Livetex on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import Foundation

public class LivetexSessionService: WebSocketDelegate {

    public var onEvent: ((ServiceEvent) -> Void)?
    public var onConnect: (() -> Void)?
    public var onDisconnect: (() -> Void)?
    public var onError: ((Error) -> Void)?

    public var eventQueue: DispatchQueue = .main {
        didSet {
            webSocket?.eventQueue = eventQueue
        }
    }

    public var isConnected: Bool {
        return webSocket?.isOpen ?? false
    }

    private let token: SessionToken

    private var webSocket: LivetexWebSocketConnection?

    private let mapper = Mapper()

    private var pingTimer = Timer()

    // MARK: - Initialization

    public init(token: SessionToken) {
        self.token = token
    }

    // MARK: - Connection

    public func connect() {
        startSession()
    }

    public func disconnect() {
        stopSession()
    }

    private func startSession() {
        webSocket?.delegate = nil
        webSocket?.closeConnection()
        let connection = makeConnection()
        connection.delegate = self
        connection.eventQueue = eventQueue
        webSocket = connection
        connection.openConnection()
    }

    private func makeConnection() -> LivetexWebSocketConnection {
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *), LivetexTrust.isEnabled {
            return LivetexURLSessionWebSocket(url: token.endpoints.ws)
        }
        return WebSocket(token.endpoints.ws)
    }

    private func stopSession() {
        webSocket?.delegate = nil
        webSocket?.closeConnection()
        webSocket = nil
    }

    // MARK: - Receive Event

    private func didReceive(payload: String) {
        do {
            let event = try mapper.decode(ServiceEvent.self, from: payload)
            onEvent?(event)
        } catch {
            onError?(error)
        }
    }

    // MARK: - Send Event

    public func sendEvent(_ event: ClientEvent) {
        eventQueue.async { [weak self] in
            do {
                let payload = try self?.mapper.encode(event) ?? ""
                self?.webSocket?.sendText(payload)
            } catch {
                self?.onError?(error)
            }
        }
    }

    // MARK: - WebSocketDelegate

    public func webSocketOpen() {
        onConnect?()
        startPingTimer()
    }

    public func webSocketMessageText(_ text: String) {
        didReceive(payload: text)
    }

    public func webSocketClose(_ code: Int, reason: String, wasClean: Bool) {
        onDisconnect?()
        stopPingTimer()
    }

    public func webSocketError(_ error: NSError) {
        onError?(error)
        stopPingTimer()
    }

    // MARK: - Timer

    private func startPingTimer() {
        pingTimer = Timer(timeInterval: 10,
                          target: self,
                          selector: #selector(onTimerScheduled),
                          userInfo: nil,
                          repeats: true)

        RunLoop.main.add(pingTimer, forMode: .common)
        pingTimer.fire()
    }

    private func stopPingTimer() {
        if pingTimer.isValid {
            pingTimer.invalidate()
        }
    }

    @objc private func onTimerScheduled() {
        webSocket?.sendPing()
    }

    // MARK: - Send File

    public func upload(data: Data,
                fileName: String,
                mimeType: String,
                completionHandler: @escaping (Result<MessageAttachment, LTError>) -> Void) {
        guard let requestURL = URL(string: token.endpoints.upload) else {
            completionHandler(.failure(LTError.invalidURL))
            return
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token.visitorToken)", forHTTPHeaderField: "Authorization")
        var uploadData = Data()
        uploadData.append("\r\n--\(boundary)\r\n".data(using: .utf8) ?? Data())
        uploadData.append("Content-Disposition: form-data; name=\"fileUpload\"; filename=\"\(fileName)\"\r\n".data(using: .utf8) ?? Data())
        uploadData.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8) ?? Data())
        uploadData.append(data)
        uploadData.append("\r\n--\(boundary)--\r\n".data(using: .utf8) ?? Data())
        LivetexTrust.session.uploadTask(with: request, from: uploadData) { data, response, error in
            if let error = error {
                completionHandler(.failure(.requestFailed(error)))
            } else {
                do {
                    let attachment = try JSONDecoder().decode(MessageAttachment.self, from: data ?? Data())
                    completionHandler(.success(attachment))
                } catch {
                    completionHandler(.failure(.decodingFailed(error)))
                }
            }
        }.resume()
    }

}
