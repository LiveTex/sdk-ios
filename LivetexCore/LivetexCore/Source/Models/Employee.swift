//
//  Employee.swift
//  LivetexMessaging
//
//  Created by Livetex on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import UIKit

public struct Employee: Codable {
    public let name: String
    public let position: String
    public let rating: String?
    public let avatarUrl: String
}

public enum EmployeeStatus: String, Codable {
    case online
    case offline
}
