//
//  ChatViewModel.swift
//  LivetexWebSocket
//
//  Created by Emil Abduselimov on 11.05.2020.
//  Copyright © 2020 Emil Abduselimov. All rights reserved.
//

import UIKit
import MessageKit

class ChatViewModel {

    var onDepartmentReceived: (([Department]) -> Void)?
    var onMessagesReceived: (() -> Void)?
    var onDialogStateReceived: ((Dialog) -> Void)?

    private(set) var messages: [MessageType] = []

    private(set) var user = Recipient(senderId: UUID().uuidString,
                                      displayName: "Тестов Тест")

    private(set) var receiver = Recipient(senderId: UUID().uuidString,
                                          displayName: "")

    private(set) var sessionService: LivetexSessionService?

    // MARK: - Initialization

    init() {
        configure()
    }

    // MARK: - Configuration

    private func configure() {
        let loginService = LivetexLoginService(clientID: "731D5678-C34C-4E87-AD28-0DCCB49BCEAA")
        loginService.requestAuthentication { [weak self] result in
            switch result {
            case let .success(token):
                self?.sessionService = LivetexSessionService(sessionToken: token)
                self?.sessionService?.onResponseReceived = { [weak self] response in
                    self?.receiveResponse(response)
                }
                self?.sessionService?.connect()
            case let .failure(error):
                print(error.localizedDescription)
            }
        }
    }

    func sendRequest(_ request: Request) {
        sessionService?.sendRequest(request)
    }


    // MARK: - Response

    private func receiveResponse(_ response: Response) {
        switch response {
        case let .result(result):
            print(result)
        case let .dialog(result):
            dialogReceived(result)
        case .attributes:
            attributesReceived()
        case let .departments(result):
            departmentsReceived(departments: result.departments)
        case let .history(result):
            messageHistoryReceived(messages: result.messages)
        default:
            print(response)
        }
    }

    private func dialogReceived(_ dialog: Dialog) {
        receiver.displayName = dialog.employee.name
        onDialogStateReceived?(dialog)
    }

    private func attributesReceived() {
        let attributes = Attributes(name: "Тестов Тест", phone: "123456789", email: "test@test.ru")
        sendRequest(.attributes(attributes))
    }

    private func departmentsReceived(departments: [Department]) {
        onDepartmentReceived?(departments)
    }

    private func messageHistoryReceived(messages: [MessageItem]) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.messages += messages.map {
                let kind: MessageKind
                let sender = $0.creator.isUser ? self.user : self.receiver
                switch $0.content {
                case let .text(text):
                    kind = .text(text)
                case let .file(attachment):
                    let file = File(url: URL(string: attachment.url),
                                    image: nil,
                                    placeholderImage: UIImage(),
                                    size: CGSize(width: 240, height: 240))
                    kind = .photo(file)
                }

                return ChatMessage(sender: sender,
                                   messageId: $0.id,
                                   sentDate: $0.createdAt,
                                   kind: kind,
                                   creator: $0.creator)
            }

            DispatchQueue.main.async {
                self.onMessagesReceived?()
            }
        }
    }

}
