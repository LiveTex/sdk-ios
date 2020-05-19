//
//  Department.swift
//  LivetexMessaging
//
//  Created by Emil Abduselimov on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import UIKit

struct Departments: Decodable {
    let type: Type
    let departments: [Department]
}

struct Department: Decodable {
    let id: String
    let name: String
    let order: Int
}
