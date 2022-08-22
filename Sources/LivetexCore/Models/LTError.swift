//
//  LTError.swift
//  LivetexCore
//
//  Created by LiveTex on 21.07.2020.
//  Copyright © 2020 LiveTex. All rights reserved.
//

public enum LTError: Error {
    case invalidURL
    case responseValidationFailed
    case requestFailed(Error)
    case decodingFailed(Error)
}
