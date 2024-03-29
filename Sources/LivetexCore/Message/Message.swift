//
//  Message.swift
//  LivetexMessaging
//
//  Created by Livetex on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import Foundation

public struct Message: MessageItem, Decodable {
    public let id: String
    public let type: MessageItemType
    public let content: MessageContent
    public let creator: Creator
    public let createdAt: Date
    public let keyboard: Keyboard?

    // MARK: - Initialization

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(MessageItemType.self, forKey: .type)
        content = try MessageContent(from: decoder)
        creator = try container.decode(Creator.self, forKey: .creator)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        keyboard = try? container.decode(Keyboard.self, forKey: .keyboard)
    }
}

extension Message {

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case creator
        case createdAt
        case keyboard
        case content
        case name
        case url
    }

}
