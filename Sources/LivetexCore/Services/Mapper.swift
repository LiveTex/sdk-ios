//
//  Mapper.swift
//  LivetexMessaging
//
//  Created by Livetex on 15.07.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import UIKit

class Mapper {

    private let message: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return dateFormatter
    }()

    private let decoder: JSONDecoder

    private let encoder: JSONEncoder

    // MARK: - Initialization

    init() {
        decoder = JSONDecoder()
        encoder = JSONEncoder()
        decoder.dateDecodingStrategy = .formatted(message)
        encoder.dateEncodingStrategy = .formatted(message)
    }

    // MARK: - Mapping

    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        return try decoder.decode(type, from: data)
    }

    func decode<T: Decodable>(_ type: T.Type, from payload: String) throws -> T {
        return try decode(type, from: payload.data(using: .utf8) ?? Data())
    }

    func encode<T: Encodable>(_ value: T) throws -> Data {
        return try encoder.encode(value)
    }

    func encode<T: Encodable>(_ value: T) throws -> String? {
        return String(data: try encode(value), encoding: .utf8)
    }

}
