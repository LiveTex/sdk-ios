//
//  LivetexSessionService.swift
//  LivetexMessaging
//
//  Created by Emil Abduselimov on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import UIKit
import Starscream

private let sessionPath = "ws://sdk-mock.livetex.ru/v1/ws"
private let uploadPath = "https://sdk-mock.livetex.ru/v1/upload"

class LivetexSessionService: WebSocketDelegate {

    var onResponseReceived: ((Response) -> Void)?

    private(set) var isConnected = false

    private let sessionToken: SessionToken

    private var webSocket: WebSocket?

    // MARK: - Initialization

    init(sessionToken: SessionToken) {
        self.sessionToken = sessionToken
        if let url = URL(string: sessionPath)?.appendingPathComponent(sessionToken.clientID) {
            self.webSocket = WebSocket(request: URLRequest(url: url))
            self.webSocket?.delegate = self
        }
    }

    // MARK: - Connection

    func connect() {
        webSocket?.connect()
    }

    func disconnect() {
        webSocket?.disconnect()
    }

    // MARK: - Receive response

    private func receiveResponse(_ payload: String) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(.message)
        guard let data = payload.data(using: .utf8),
              let response = try? decoder.decode(Response.self, from: data) else {
            return
        }

        onResponseReceived?(response)
    }

    func sendRequest(_ request: Request) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(.message)
        guard let data = try? encoder.encode(request),
              let payload = String(data: data, encoding: .utf8) else {
            return
        }

        webSocket?.write(string: payload)
    }

    // MARK: - WebSocketDelegate

    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected:
            isConnected = true
        case .disconnected(let reason, let code):
            isConnected = false
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let payload):
            receiveResponse(payload)
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping(_):
            print("ping")
            break
        case .pong(_):
            print("pong")
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            isConnected = false
        case .error(let error):
            isConnected = false
            handleError(error)
        }
    }

    func handleError(_ error: Error?) {
        if let e = error as? WSError {
            print("websocket encountered an error: \(e.message)")
        } else if let e = error {
            print("websocket encountered an error: \(e.localizedDescription)")
        } else {
            print("websocket encountered an error")
        }
    }

    func upload(data: Data, fileName: String, mimeType: String, completionHandler: @escaping (Result<MessageAttachment, Error>) -> Void) {
        guard let requestURL = URL(string: uploadPath) else {
            return
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var uploadData = Data()
        uploadData.append("\r\n--\(boundary)\r\n".data(using: .utf8) ?? Data())
        uploadData.append("Content-Disposition: form-data; name=\"fileUpload\"; filename=\"\(fileName)\"\r\n".data(using: .utf8) ?? Data())
        uploadData.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8) ?? Data())
        uploadData.append(data)
        uploadData.append("\r\n--\(boundary)--\r\n".data(using: .utf8) ?? Data())
        URLSession.shared.uploadTask(with: request, from: uploadData) { data, result, error in
            guard let responseData = data,
                  let attachment = try? JSONDecoder().decode(MessageAttachment.self, from: responseData) else {
                return
            }

            completionHandler(.success(attachment))
        }.resume()
    }

}
