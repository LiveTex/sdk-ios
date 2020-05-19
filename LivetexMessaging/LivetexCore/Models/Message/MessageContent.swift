//
//  MessageContent.swift
//  LivetexMessaging
//
//  Created by Emil Abduselimov on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import UIKit

enum MessageContent: Decodable {
    case text(String)
    case file(MessageAttachment)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            self = .text(try container.decode(String.self))
        } catch DecodingError.typeMismatch {
            self = .file(try container.decode(MessageAttachment.self))
        }
    }

}

struct MessageAttachment: Codable {
    let name: String
    let url: String
}
