//
//  ClientEvent.swift
//  LivetexMessaging
//
//  Created by Livetex on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import Foundation

public struct ClientEvent: Encodable {
    public let correlationID = UUID().uuidString
    public let content: Content

    // MARK: - Initialization

    public init(_ content: Content) {
        self.content = content
    }

    // MARK: - Encoding

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(correlationID, forKey: .correlationId)
        try content.encode(to: encoder)
    }
}
