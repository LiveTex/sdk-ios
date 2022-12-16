//
//  MessageContent.swift
//  LivetexMessaging
//
//  Created by Livetex on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

public enum MessageContent: Decodable {
    case text(String)
    case file(MessageAttachment)

    // MARK: - Initialization

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.content) {
            self = .text(try container.decode(String.self, forKey: .content))
        } else {
            self = .file(MessageAttachment(name: try container.decode(String.self, forKey: .name),
                                           url: try container.decode(String.self, forKey: .url)))
        }
    }
}

extension MessageContent {

    enum CodingKeys: String, CodingKey {
        case url
        case name
        case type
        case content
    }

}

public struct MessageAttachment: Codable {
    public let name: String
    public let url: String
}
