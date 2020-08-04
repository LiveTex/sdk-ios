//
//  ClientEvent+Type.swift
//  LivetexMessaging
//
//  Created by Livetex on 14.07.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

public extension ClientEvent {

    enum EventType: String, Codable {
        case text
        case file
        case rating
        case typing
        case attributes
        case department
        case getHistory
        case buttonPressed
    }

}
