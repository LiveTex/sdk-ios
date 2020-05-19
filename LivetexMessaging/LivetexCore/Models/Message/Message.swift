//
//  Message.swift
//  LivetexMessaging
//
//  Created by Emil Abduselimov on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import UIKit

struct Message: MessageItem, Decodable {

    private(set) var id: String
    private(set) var type: Type
    private(set) var content: MessageContent
    private(set) var creator: Creator
    private(set) var createdAt: Date

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(Type.self, forKey: .type)
        switch type {
        case .file:
            content = .file(MessageAttachment(name: try container.decode(String.self, forKey: .name),
                                              url: try container.decode(String.self, forKey: .url)))
        default:
            content = .text(try container.decode(String.self, forKey: .content))
        }
        creator = try container.decode(Creator.self, forKey: .creator)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

}

extension Message {

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case creator
        case createdAt
        case content
        case name
        case url
    }

}
