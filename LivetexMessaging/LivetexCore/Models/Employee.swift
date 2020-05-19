//
//  Employee.swift
//  LivetexMessaging
//
//  Created by Emil Abduselimov on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import UIKit

struct Creator: Codable {
    let type: CreatorType
    let employee: Employee?

    var isUser: Bool {
        return employee == nil
    }

    enum CreatorType: String, Codable {
        case user
        case employee
    }
}

struct Employee: Codable {
    let name: String
    let position: String
    let avatarUrl: String
}
