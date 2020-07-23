//
//  ResultMessage.swift
//  LivetexMessaging
//
//  Created by Livetex on 05.07.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import UIKit

public struct ResultMessage: Codable {
    public let correlationId: String
    public let type: ServiceEvent.EventType
    public let sentMessage: SentMessage?
    public let error: [ResponseError]

    public struct SentMessage: Codable {
        let id: String
        let createdAt: Date
    }
}

public enum ResponseError: String, Codable {
    case systemUnavailable
    case fileNoName
    case fileNoUrl
    case contentIsEmpty
    case attributesWrongFormat
    case departmentNoId
    case departmentInvalidId
}
