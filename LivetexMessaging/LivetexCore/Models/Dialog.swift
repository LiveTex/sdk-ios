//
//  Dialog.swift
//  LivetexMessaging
//
//  Created by Emil Abduselimov on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import UIKit

struct Dialog: Decodable {
    let type: Type
    let status: Status
    let employeeStatus: EmployeeStatus
    let employee: Employee

    enum Status: String, Codable {
        case unassigned
        case inQueue
        case assigned
        case aiBot
    }

    enum EmployeeStatus: String, Codable {
        case online
        case offline
    }
}
