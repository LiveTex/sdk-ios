//
//  Request.swift
//  LivetexMessaging
//
//  Created by Emil Abduselimov on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import UIKit

enum Request: Encodable {

    enum CodingKeys: String, CodingKey {
        case correlationId
        case type
    }

    struct Key: CodingKey {
        var stringValue: String
        var intValue: Int?

        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        init?(intValue: Int) {
            return nil
        }
    }

    case text(String)
    case file(MessageAttachment)
    case typing(String)
    case attributes(Attributes)
    case department(String)

    var type: Type {
        switch self {
        case .text:
            return .text
        case .file:
            return .file
        case .typing:
            return .typing
        case .attributes:
            return .attributes
        case .department:
            return .department
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(UUID().uuidString, forKey: .correlationId)
        try container.encode(type, forKey: .type)

        switch self {
        case let .text(content):
            guard let key = Key(stringValue: "content") else {
                return
            }
            var container = encoder.container(keyedBy: Key.self)
            try container.encode(content, forKey: key)
        case let .file(attachment):
            try attachment.encode(to: encoder)
        case let .typing(content):
            guard let key = Key(stringValue: "content") else {
                return
            }
            var container = encoder.container(keyedBy: Key.self)
            try container.encode(content, forKey: key)
        case let .attributes(content):
            try content.encode(to: encoder)
        case let .department(content):
            guard let key = Key(stringValue: "id") else {
                return
            }
            var container = encoder.container(keyedBy: Key.self)
            try container.encode(content, forKey: key)
        }
    }
}
