//
//  MessageItem.swift
//  LivetexMessaging
//
//  Created by Emil Abduselimov on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import UIKit

protocol MessageItem {

    var id: String { get }

    var type: Type { get }

    var creator: Creator { get }

    var createdAt: Date { get }

    var content: MessageContent { get }

}
