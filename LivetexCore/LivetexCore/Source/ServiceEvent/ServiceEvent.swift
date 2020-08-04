//
//  ServiceEvent.swift
//  LivetexMessaging
//
//  Created by Livetex on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

public enum ServiceEvent: Decodable {
    case attributes
    case employeeTyping
    case update(Update)
    case result(ResultMessage)
    case departments(Departments)
    case state(Conversation)

    // MARK: - Initialization

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(EventType.self, forKey: .type)
        switch type {
        case .result:
            self = .result(try decoder.singleValueContainer().decode(ResultMessage.self))
        case .state:
            self = .state(try decoder.singleValueContainer().decode(Conversation.self))
        case .attributesRequest:
            self = .attributes
        case .departmentRequest:
            self = .departments(try decoder.singleValueContainer().decode(Departments.self))
        case .update:
            self = .update(try decoder.singleValueContainer().decode(Update.self))
        case .employeeTyping:
            self = .employeeTyping
        }
    }
}
