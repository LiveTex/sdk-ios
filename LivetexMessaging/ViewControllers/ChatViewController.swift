//
//  ChatViewController.swift
//  LivetexMessaging
//
//  Created by Emil Abduselimov on 19.05.2020.
//  Copyright © 2020 Livetex. All rights reserved.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import Kingfisher

class ChatViewController: MessagesViewController,
                          InputBarAccessoryViewDelegate,
                          DepartmentsPickerViewDelegate {

    private let titleView = TitleView()

    private let avatarView = OperatorAvatarView()

    private let viewModel = ChatViewModel()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureInputBar()
        configureViewModel()
        configureCollectionView()
        configureNavigationItem()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let navigationBarFrame = navigationController?.navigationBar.frame ?? .zero
        titleView.frame = CGRect(x: 0,
                                 y: 0,
                                 width: 0.7 * navigationBarFrame.width,
                                 height: navigationBarFrame.height)

        avatarView.frame = CGRect(origin: .zero, size: CGSize(width: 30, height: 30))
    }

    // MARK: - Configuration

    private func configureViewModel() {
        viewModel.onDepartmentReceived = { [weak self] departments in
            guard let self = self else {
                return
            }

            let departmentsView = DepartmentsPickerView(frame: CGRect(origin: .zero,
                                                                      size: CGSize(width: self.view.bounds.width,
                                                                                   height: 200)))
            departmentsView.departments = departments
            departmentsView.delegate = self
            self.messageInputBar.inputTextView.inputView = departmentsView
            self.messageInputBar.inputTextView.reloadInputViews()
            self.messageInputBar.inputTextView.becomeFirstResponder()
        }

        viewModel.onMessagesReceived = { [weak self] in
            self?.messagesCollectionView.reloadData()
            self?.messagesCollectionView.scrollToBottom()
        }

        viewModel.onDialogStateReceived = { [weak self] dialog in
            self?.titleView.title = dialog.employee.name
            self?.titleView.subtitle = dialog.employeeStatus.rawValue
            self?.avatarView.setImage(with: URL(string: dialog.employee.avatarUrl))
        }
    }

    private func configureCollectionView() {
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self

        let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout
        layout?.sectionInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        layout?.setMessageOutgoingMessageTopLabelAlignment(LabelAlignment(textAlignment: .right,
                                                                          textInsets: UIEdgeInsets(top: 0,
                                                                                                   left: 0,
                                                                                                   bottom: 0,
                                                                                                   right: 16)))
        layout?.setMessageIncomingMessageTopLabelAlignment(LabelAlignment(textAlignment: .left,
                                                                          textInsets: UIEdgeInsets(top: 0,
                                                                                                   left: 48,
                                                                                                   bottom: 0,
                                                                                                   right: 0)))

        layout?.setMessageOutgoingAvatarSize(.zero)
        layout?.setMessageIncomingAvatarSize(CGSize(width: 30, height: 30))

        scrollsToBottomOnKeyboardBeginsEditing = true
        maintainPositionOnKeyboardFrameChanged = true
    }

    private func configureNavigationItem() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: avatarView)
        navigationItem.titleView = titleView
    }

    private func configureInputBar() {
        let attachmentButton = InputBarButtonItem()
            .configure {
                $0.image = UIImage(named: "attach")?.withRenderingMode(.alwaysTemplate)
                $0.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
                $0.tintColor = messageInputBar.sendButton.tintColor
                $0.setSize(CGSize(width: 52, height: 36), animated: false)
            }.onTouchUpInside { [weak self] item in
                let imagePickerController = UIImagePickerController()
                imagePickerController.delegate = self
                self?.present(imagePickerController, animated: true)
            }

        messageInputBar.delegate = self
        messageInputBar.inputTextView.tintColor = UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1)
        messageInputBar.inputTextView.placeholder = "Message..."
        messageInputBar.setLeftStackViewWidthConstant(to: 30, animated: false)
        messageInputBar.setStackViewItems([attachmentButton], forStack: .left, animated: false)
    }

    // MARK: - DepartmentsPickerViewDelegate

    func pickerView(_ pickerView: DepartmentsPickerView, didSelect item: Department) {
        messageInputBar.inputTextView.inputView = nil
        messageInputBar.inputTextView.reloadInputViews()
        viewModel.sendRequest(.department(item.id))
    }

    // MARK: - InputBarAccessoryViewDelegate

    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        messageInputBar.inputTextView.text = ""
        messageInputBar.invalidatePlugins()
        viewModel.sendRequest(.text(trimmedText))
    }

    func inputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String) {
        guard !text.isEmpty else {
            return
        }

        viewModel.sendRequest(.typing(text))
    }

}

extension ChatViewController: MessagesDataSource {

    func currentSender() -> SenderType {
        return viewModel.user
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return viewModel.messages.count
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return viewModel.messages[indexPath.section]
    }

    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if indexPath.section % 3 == 0 {
            return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate),
                                      attributes: [.font: UIFont.boldSystemFont(ofSize: 10),
                                                   .foregroundColor: UIColor.darkGray])
        }

        return nil
    }

    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(string: name, attributes: [.font: UIFont.preferredFont(forTextStyle: .caption1)])
    }

}

extension ChatViewController: MessagesDisplayDelegate, MessagesLayoutDelegate {

    func cellTopLabelHeight(for message: MessageType,
                            at indexPath: IndexPath,
                            in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return indexPath.section % 3 == 0 ? 18 : 0
    }

    func messageTopLabelHeight(for message: MessageType,
                               at indexPath: IndexPath,
                               in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 20
    }

    func messageStyle(for message: MessageType,
                      at indexPath: IndexPath,
                      in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let tail: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(tail, .curved)
    }

    func configureMediaMessageImageView(_ imageView: UIImageView,
                                        for message: MessageType,
                                        at indexPath: IndexPath,
                                        in messagesCollectionView: MessagesCollectionView) {
        switch message.kind {
        case let .photo(item):
            guard let imageURL = item.url else {
                return
            }
            imageView.kf.setImage(with: .network(ImageResource(downloadURL: imageURL)))
        default:
            return
        }
    }

    func configureAvatarView(_ avatarView: AvatarView,
                             for message: MessageType,
                             at indexPath: IndexPath,
                             in messagesCollectionView: MessagesCollectionView) {
        guard let chatMessage = message as? ChatViewModel.ChatMessage,
              let urlString = chatMessage.creator.employee?.avatarUrl,
              let resourceURL = URL(string: urlString) else {
            return
        }

        avatarView.kf.setImage(with: ImageResource(downloadURL: resourceURL))
    }

}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        /*
        guard let image = info[.originalImage] as? UIImage else {
            picker.dismiss(animated: true)
            return
        }*/

        viewModel.sessionService?.upload(data: UIImage().pngData() ?? Data(),
                                         fileName: "Image",
                                         mimeType: "image/png") { [weak self] result in
            switch result {
            case let .success(attachment):
                self?.viewModel.sendRequest(.file(attachment))
            case let .failure(error):
                print(error.localizedDescription)
            }
        }

        picker.dismiss(animated: true)
    }

}

