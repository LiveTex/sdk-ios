//
//  LivetexAuthService.swift
//  LivetexMessaging
//
//  Created by Livetex on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import Foundation

//public enum Token {
//    case system(String)
//    case custom(String)
//}

public struct AuthData {
    let customVisitorToken: String?
    let visitorToken: String?
}

private let defaultAuthPath = "https://visitor-api.livetex.ru/v1/auth"

public class LivetexAuthService {

  //  private let token: Token?

    private let deviceToken: String
    private let authPath: String?
    private let visitorToken: String?
    private let customVisitorToken: String?

    // MARK: - Initialization

    public init(visitorToken: String?,
                customVisitorToken: String?,
                deviceToken: String,
                authPath: String? = nil) {
        self.visitorToken = visitorToken
        self.customVisitorToken = customVisitorToken
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


        switch (visitorToken, customVisitorToken) {
        case (visitorToken, customVisitorToken):
            components?.queryItems?.append(URLQueryItem(name: "visitorToken", value: visitorToken))
            components?.queryItems?.append(URLQueryItem(name: "customVisitorToken", value: customVisitorToken))
        case (visitorToken, nil):
            components?.queryItems?.append(URLQueryItem(name: "visitorToken", value: visitorToken))
        case (nil, customVisitorToken):
            components?.queryItems?.append(URLQueryItem(name: "customVisitorToken", value: customVisitorToken))
        default:
            components?.queryItems?.append(URLQueryItem(name: "visitorToken", value: ""))
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
