//
//  Response.swift
//  LivetexMessaging
//
//  Created by Emil Abduselimov on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import UIKit

struct ResultMessage: Codable {
    let correlationId: String
    let type: Type
    let sentMessage: SentMessage
    let error: [ResponseError]
}

struct SentMessage: Codable {
    let id: String
    let createdAt: Date
}

struct MessageHistory: Decodable {
    let correlationId: String
    let type: Type
    let createdAt: Date
    let messages: [Message]
}

enum Response: Decodable {
    enum CodingKeys: String, CodingKey {
        case type
    }

    case result(ResultMessage)
    case history(MessageHistory)
    case dialog(Dialog)
    case attributes
    case departments(Departments)
    case unknown

    // MARK: - Decoding

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(Type.self, forKey: .type)
        switch type {
        case .result:
            self = .result(try decoder.singleValueContainer().decode(ResultMessage.self))
        case .state:
            self = .dialog(try decoder.singleValueContainer().decode(Dialog.self))
        case .attributesRequest:
            self = .attributes
        case .departmentRequest:
            self = .departments(try decoder.singleValueContainer().decode(Departments.self))
        case .update:
            self = .history(try decoder.singleValueContainer().decode(MessageHistory.self))
        default:
            self = .unknown
        }
    }
}

enum ResponseError: String, Codable {
    case systemUnavailable
    case fileNoName
    case fileNoUrl
    case contentIsEmpty
    case attributesWrongFormat
    case departmentNoId
    case departmentInvalidId
}
