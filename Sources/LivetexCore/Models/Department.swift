//
//  Department.swift
//  LivetexMessaging
//
//  Created by Livetex on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

public struct Departments: Decodable {
    public let type: ServiceEvent.EventType
    public let departments: [Department]
}

public struct Department: Decodable {
    public let id: String
    public let name: String
    public let order: Int
}
