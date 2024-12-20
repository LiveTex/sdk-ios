//
//  ClientEvent+Content.swift
//  LivetexMessaging
//
//  Created by Livetex on 17.07.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

public extension ClientEvent {

    enum Content: Encodable {
        case text(String)
        case file(MessageAttachment)
        case typing(String)
        case rating(SendVoteResult, String?)
        case department(String)
        case getHistory(String, Int)
        case attributes(Attributes)
        case buttonPressed(String)

        // MARK: - Encoding

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case let .rating(value, text):
                try container.encode(ClientEvent.EventType.rating, forKey: .type)
                try container.encode(value, forKey: .rate)
                try container.encode(text, forKey: .comment )
            case let .text(content):
                try container.encode(ClientEvent.EventType.text, forKey: .type)
                try container.encode(content, forKey: .content)
            case let .file(attachment):
                try container.encode(ClientEvent.EventType.file, forKey: .type)
                try attachment.encode(to: encoder)
            case let .typing(content):
                try container.encode(ClientEvent.EventType.typing, forKey: .type)
                try container.encode(content, forKey: .content)
            case let .getHistory(id, offset):
                if id.isEmpty {
                    let context = EncodingError.Context(codingPath: container.codingPath,
                                                        debugDescription: "Value is empty")
                    throw EncodingError.invalidValue(id, context)
                } else {
                    try container.encode(id, forKey: .messageId)
                }
                try container.encode(ClientEvent.EventType.getHistory, forKey: .type)
                try container.encode(offset, forKey: .offset)
            case let .attributes(content):
                try container.encode(ClientEvent.EventType.attributes, forKey: .type)
                try content.encode(to: encoder)
            case let .department(id):
                if id.isEmpty {
                    let context = EncodingError.Context(codingPath: container.codingPath,
                                                        debugDescription: "Value is empty")
                    throw EncodingError.invalidValue(id, context)
                } else {
                    try container.encode(id, forKey: .id)
                }
                try container.encode(ClientEvent.EventType.department, forKey: .type)
            case let .buttonPressed(content):
                try container.encode(ClientEvent.EventType.buttonPressed, forKey: .type)
                try container.encode(content, forKey: .payload)
            }
        }
    }

}
