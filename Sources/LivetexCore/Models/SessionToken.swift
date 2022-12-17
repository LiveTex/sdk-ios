//
//  SessionToken.swift
//  LivetexMessaging
//
//  Created by Livetex on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

public struct SessionToken: Decodable {
    public let visitorToken: String
    public let endpoints: Endpoint
}
