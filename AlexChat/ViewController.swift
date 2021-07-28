//
//  ViewController.swift
//  AlexChat
//
//  Created by Alex Lee on 6/9/21.
//  Copyright © 2021 Alex Lee. All rights reserved.
//

import UIKit

import MessageKit
import InputBarAccessoryView

class ViewController: MessagesViewController {
    var viewModel: ChatViewModel!
    var titleView: UILabel?
    
    let messageDateFormatter = DateFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.messagesCollectionView.messagesDataSource = self
        self.messagesCollectionView.messagesLayoutDelegate = self
        self.messagesCollectionView.messagesDisplayDelegate = self
        self.messageInputBar.delegate = self
        
        messageDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        self.setTitleView()
        
        scrollsToBottomOnKeyboardBeginsEditing = true
        maintainPositionOnKeyboardFrameChanged = true

        let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout

        layout?.textMessageSizeCalculator.incomingAvatarPosition = AvatarPosition(vertical: .messageBottom)
        layout?.textMessageSizeCalculator.outgoingAvatarPosition = AvatarPosition(vertical: .messageBottom)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.viewModel.listener = { [weak self] (changeType) in
          DispatchQueue.main.async {
            switch changeType {
            case .messages:
              self?.messagesCollectionView.reloadData()
              self?.messagesCollectionView.scrollToBottom(animated: true)
            case .occupancy:
              self?.setTitleView()
            case .connected(let isConnected):
              if isConnected {
                self?.messageInputBar.shouldManageSendButtonEnabledState = true
                // Enable the send button only if there is text entered
                if !(self?.messageInputBar.inputTextView.text.isEmpty ?? true) {
                  self?.messageInputBar.sendButton.isEnabled = true
                }
              } else {
                self?.messageInputBar.shouldManageSendButtonEnabledState = false
                self?.messageInputBar.sendButton.isEnabled = false
              }
              self?.setTitleView()
            }
          }
        }
        self.viewModel.bind()

        self.setTitleView()
        self.messagesCollectionView.reloadData()
        self.messagesCollectionView.scrollToBottom(animated: true)
    }
    
    func setTitleView() {
        if titleView == nil {
          titleView = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 35.0))
          titleView?.widthAnchor.constraint(equalToConstant: 150.0).isActive = true
          titleView?.heightAnchor.constraint(equalToConstant: 35.0).isActive = true
          titleView?.backgroundColor = UIColor.clear
          titleView?.numberOfLines = 0
          titleView?.textAlignment = NSTextAlignment.left

          self.navigationItem.titleView = titleView
        }

        titleView?.text = "AlexChatRoom"
      }
}

// MARK: MessagesDataSource
extension ViewController: MessagesDataSource, MessagesDisplayDelegate, MessagesLayoutDelegate {
    func currentSender() -> SenderType {
        return viewModel.sender ?? User(uuid: "alexlee-test", name: "Alex Lee")
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return viewModel.messages[indexPath.section]
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return viewModel.messages.count
    }

    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        avatarView.isHidden = true
    }
}

extension ViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        for component in inputBar.inputTextView.components {
            if let message = component as? String {
                viewModel.send(message) { (_) in
                    DispatchQueue.main.async { [weak self] in
                        self?.messagesCollectionView.reloadData()
                    }
                }
            }
        }
        DispatchQueue.main.async { [weak self] in
            self?.messagesCollectionView.reloadData()
            inputBar.inputTextView.text = String()
            self?.messagesCollectionView.scrollToBottom(animated: true)
        }
    }
}
