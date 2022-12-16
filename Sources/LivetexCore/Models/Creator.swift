//
//  Creator.swift
//  LivetexMessaging
//
//  Created by Livetex on 05.07.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

public struct Creator: Codable {
    public let type: CreatorType
    public let employee: Employee?

    public var isVisitor: Bool {
        return type == .visitor
    }

    public enum CreatorType: String, Codable {
        case visitor
        case employee
        case system
        case bot
    }
}
