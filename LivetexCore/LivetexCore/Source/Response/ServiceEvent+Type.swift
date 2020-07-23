//
//  ServiceEvent+Type.swift
//  LivetexMessaging
//
//  Created by Livetex on 14.07.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

public extension ServiceEvent {

    enum EventType: String, Codable {
        case state
        case result
        case update
        case employeeTyping
        case departmentRequest
        case attributesRequest
    }

}
