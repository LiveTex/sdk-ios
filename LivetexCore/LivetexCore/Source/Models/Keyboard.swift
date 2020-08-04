//
//  Keyboard.swift
//  LivetexCore
//
//  Created by Emil Abduselimov on 28.07.2020.
//  Copyright © 2020 LiveTex. All rights reserved.
//

import UIKit

public struct Keyboard: Decodable {
    public let buttons: [Button]
    public let pressed: Bool
}

public struct Button: Decodable {
    public let url: String?
    public let label: String
    public let payload: String
}
