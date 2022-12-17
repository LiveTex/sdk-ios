//
//  Update.swift
//  LivetexMessaging
//
//  Created by Livetex on 05.07.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import Foundation

public struct Update: Decodable {
    public let correlationId: String?
    public let type: ServiceEvent.EventType
    public let createdAt: Date
    public let messages: [Message]
}
