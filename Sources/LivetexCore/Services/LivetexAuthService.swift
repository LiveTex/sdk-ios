//
//  LivetexAuthService.swift
//  LivetexMessaging
//
//  Created by Livetex on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import Foundation

private let defaultAuthPath = "https://visitor-api.livetex.ru/v1/auth"

public class LivetexAuthService {

    private let deviceToken: String?
    private let authPath: String?
    private let visitorToken: String?
    private let customVisitorToken: String?

    // MARK: - Initialization

    public init(visitorToken: String? = nil,
                customVisitorToken: String? = nil,
                deviceToken: String? = nil,
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
            URLQueryItem(name: "deviceType", value: "ios"),
            URLQueryItem(name: "visitorToken", value: visitorToken),
            URLQueryItem(name: "customVisitorToken", value: customVisitorToken)
        ].filter { $0.value != nil }

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
