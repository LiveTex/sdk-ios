//
//  LivetexAuthService.swift
//  LivetexMessaging
//
//  Created by Livetex on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import UIKit

public enum Token {
    case system(String)
    case custom(String)
}

private let defaultAuthPath = "https://visitor-api.livetex.ru/v1/auth"

public class LivetexAuthService {

    private let token: Token?

    private let deviceToken: String

    private let authPath: String?

    // MARK: - Initialization

    public init(token: Token? = nil,
                deviceToken: String,
                authPath: String? = nil) {
        self.token = token
        self.deviceToken = deviceToken
        self.authPath = authPath
    }

    // MARK: - Authentication

    public func requestAuthorization(result: @escaping (Result<SessionToken, LTError>) -> Void) {
        let livetexInfo = Bundle.main.infoDictionary?["Livetex"] as? [String: String]
        var components = URLComponents(string: authPath ?? defaultAuthPath)
        components?.queryItems = [
            URLQueryItem(name: "touchPoint", value: livetexInfo?["LivetexAppID"]),
            URLQueryItem(name: "deviceToken", value: deviceToken),
            URLQueryItem(name: "deviceType", value: "ios")
        ].filter { $0.value != nil }

        if let token = token {
            switch token {
            case let .system(value):
                components?.queryItems?.append(URLQueryItem(name: "visitorToken", value: value))
            case let .custom(value):
                components?.queryItems?.append(URLQueryItem(name: "customVisitorToken", value: value))
            }
        }

        guard let authURL = components?.url else {
            result(.failure(.invalidURL))
            return
        }

        URLSession.shared.dataTask(with: authURL) { data, response, error in
            if let error = error {
                result(.failure(.requestFailed(error)))
            } else {
                guard let response = response as? HTTPURLResponse,
                      response.statusCode == 200, let responseData = data else {
                          result(.failure(.responseValidationFailed))
                          return
                      }

                do {
                    let token = try JSONDecoder().decode(SessionToken.self, from: responseData)
                    result(.success(token))
                } catch {
                    result(.failure(.decodingFailed(error)))
                }
            }
        }.resume()
    }

}
