//
//  LivetexSessionService.swift
//  LivetexMessaging
//
//  Created by Livetex on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import UIKit

public class LivetexSessionService: WebSocketDelegate {

    public var onEvent: ((ServiceEvent) -> Void)?
    public var onConnect: (() -> Void)?
    public var onDisconnect: (() -> Void)?
    public var onError: ((Error) -> Void)?

    public var eventQueue: DispatchQueue = .main {
        didSet {
            webSocket.eventQueue = eventQueue
        }
    }

    public var isConnected: Bool {
        return webSocket.readyState == .open
    }

    private let token: SessionToken

    private var webSocket = WebSocket()

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
        webSocket = WebSocket(token.endpoints.ws)
        webSocket.delegate = self
        webSocket.eventQueue = eventQueue
        webSocket.open()
    }

    private func stopSession() {
        webSocket.delegate = nil
        webSocket.close()
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
        eventQueue.async {
            do {
                let payload = try self.mapper.encode(event) ?? ""
                self.webSocket.send(text: payload)
            } catch {
                self.onError?(error)
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
        webSocket.ping()
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
        URLSession.shared.uploadTask(with: request, from: uploadData) { data, response, error in
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
