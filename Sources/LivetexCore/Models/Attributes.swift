//
//  Attributes.swift
//  LivetexMessaging
//
//  Created by Livetex on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

public struct Attributes: Encodable {
    public let name: String
    public let phone: String
    public let email: String
    public var attributes: [String: String] = [:]

    // MARK: - Initialization

    public init(name: String, phone: String, email: String, attributes: [String: String] = [:]) {
        self.name = name
        self.phone = phone
        self.email = email
        self.attributes = attributes
    }
}
