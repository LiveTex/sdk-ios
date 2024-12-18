//
//  ClientEvent.swift
//  LivetexMessaging
//
//  Created by Livetex on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import Foundation

public struct ClientEvent: Encodable {
    public let correlationId = UUID().uuidString
    public let content: Content
    public let comment: String? = nil
    
    // MARK: - Initialization

    public init(_ content: Content) {
        self.content = content
    }

    // MARK: - Encoding

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(correlationId, forKey: .correlationId)
        if let comment = comment {
            try container.encode(comment, forKey: .comment)
        }
        try content.encode(to: encoder)
    }
}
