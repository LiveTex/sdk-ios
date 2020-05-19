//
//  ChatViewModel+Messages.swift
//  LivetexWebSocket
//
//  Created by Emil Abduselimov on 13.05.2020.
//  Copyright © 2020 Emil Abduselimov. All rights reserved.
//

import UIKit
import MessageKit

extension ChatViewModel {

    struct ChatMessage: MessageType {
        var sender: SenderType
        var messageId: String
        var sentDate: Date
        var kind: MessageKind
        var creator: Creator
    }

    struct Recipient: SenderType {
        var senderId: String
        var displayName: String
    }

    struct File: MediaItem {
        var url: URL?

        var image: UIImage?

        var placeholderImage: UIImage

        var size: CGSize
    }

}
