//
//  MessageItem.swift
//  LivetexMessaging
//
//  Created by Livetex on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import Foundation

protocol MessageItem {

    var id: String { get }

    var type: MessageItemType { get }

    var creator: Creator { get }

    var createdAt: Date { get }

    var keyboard: Keyboard? { get }

    var content: MessageContent { get }

}
