//
//  LivetexLoginService.swift
//  LivetexMessaging
//
//  Created by Emil Abduselimov on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import UIKit

private let authPath = "https://sdk-mock.livetex.ru/v1/auth"

class LivetexLoginService {

    private let clientID: String?

    // MARK: - Initialization

    init(clientID: String? = nil) {
        self.clientID = clientID
    }

    // MARK: - Authentication

    func requestAuthentication(result: @escaping (Result<SessionToken, Error>) -> Void) {
        let livetexInfo = Bundle.main.infoDictionary?["Livetex"] as? [String: String]
        var components = URLComponents(string: authPath)
        components?.queryItems = [
            URLQueryItem(name: "touchPoint", value: livetexInfo?["LivetexAppID"]),
            URLQueryItem(name: "deviceId", value: livetexInfo?["LivetexDeviceID"]),
            URLQueryItem(name: "deviceType", value: livetexInfo?["LivetexDeviceType"])
        ].filter { $0.value != nil }

        components?.queryItems?.append(URLQueryItem(name: "clientId",
                                                    value: clientID ?? UUID().uuidString))

        guard let authURL = components?.url else {
            return
        }

        URLSession.shared.dataTask(with: authURL) { data, response, error in
            guard let responseData = data, let clientID = String(data: responseData, encoding: .utf8) else {
                return
            }

            result(.success(SessionToken(clientID: clientID)))
        }.resume()
    }

}
