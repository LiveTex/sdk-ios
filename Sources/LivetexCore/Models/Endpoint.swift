//
//  Endpoint.swift
//  LivetexMessaging
//
//  Created by Livetex on 23.06.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import UIKit

public struct Endpoint: Decodable {
    public let ws: String
    public let upload: String
}
