//
//  Keyboard.swift
//  LivetexCore
//
//  Created by Emil Abduselimov on 28.07.2020.
//  Copyright © 2020 LiveTex. All rights reserved.
//

public struct Keyboard: Decodable {
    public let buttons: [Button]
    public let pressed: Bool

    // MARK: - Initialization

    public init(buttons: [Button], pressed: Bool) {
        self.buttons = buttons
        self.pressed = pressed
    }
}

public struct Button: Decodable {
    public let url: String?
    public let label: String
    public let payload: String
}
