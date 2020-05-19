//
//  Attributes.swift
//  LivetexMessaging
//
//  Created by Emil Abduselimov on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import UIKit

struct Attributes: Codable {
    let name: String
    let phone: String
    let email: String
    let attributes: [String: String] = [:]
}
