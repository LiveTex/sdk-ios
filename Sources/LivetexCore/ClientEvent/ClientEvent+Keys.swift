//
//  ClientEvent+Keys.swift
//  LivetexMessaging
//
//  Created by Livetex on 17.07.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import UIKit

extension ClientEvent {

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case value
        case offset
        case content
        case payload
        case messageId
        case correlationId
    }

}
