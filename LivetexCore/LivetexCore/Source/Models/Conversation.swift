//
//  Dialog.swift
//  LivetexMessaging
//
//  Created by Livetex on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import UIKit

public struct Conversation: Decodable {
    public let type: ServiceEvent.EventType
    public let status: Status
    public let employeeStatus: EmployeeStatus?
    public let employee: Employee?

    public var isEmployeeEstimated: Bool {
        guard let employee = employee else {
            return true
        }

        return employee.rating != nil
    }

    public enum Status: String, Codable {
        case unassigned
        case inQueue
        case assigned
        case aiBot
    }
}
