//
//  Type.swift
//  LivetexMessaging
//
//  Created by Emil Abduselimov on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import UIKit

enum Type: String, Codable {
    case typing
    case text
    case file
    case state
    case result
    case department
    case update
    case attributes
    case employeeTyping
    case departmentRequest
    case attributesRequest
}
