//
//  QMSClient.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 28.11.2025.
//

import APIClient
import Dependencies
import DependenciesMacros
import Foundation
import Models
import PDAPI
import ParsingClient

@DependencyClient
public struct QMSClient: Sendable {
    public var loadQMSList: @Sendable () async throws -> QMSList
    public var loadQMSUser: @Sendable (_ id: Int) async throws -> QMSUser
    public var loadQMSChat: @Sendable (_ id: Int) async throws -> QMSChat
    public var sendQMSMessage: @Sendable (_ chatId: Int, _ message: String) async throws -> Void
}

extension QMSClient: DependencyKey {
    
    private static var api: API {
        return APIClient.api
    }
    
    // MARK: - Live Value
    
    public static var liveValue: QMSClient {
        @Dependency(\.parsingClient) var parser
        
        return QMSClient(
            loadQMSList: {
                let response = try await api.send(QMSCommand.list)
                return try await parser.parseQmsList(response)
            },
            
            loadQMSUser: { id in
                let response = try await api.send(QMSCommand.info(id: id))
                return try await parser.parseQmsUser(response)
            },
            
            loadQMSChat: { id in
                let request = QMSViewDialogRequest(dialogId: id, messageId: 0, limit: 0)
                let response = try await api.send(QMSCommand.Dialog.view(data: request))
                return try await parser.parseQmsChat(response)
            },
            
            sendQMSMessage: { chatId, message in
                let request = QMSSendMessageRequest(dialogId: chatId, message: message, fileList: [])
                let _ = try await api.send(QMSCommand.Message.send(data: request))
            }
        )
    }
    
    // MARK: - Preview Value
    
    public static var previewValue: QMSClient {
        let mock = QMSClientMock()
        
        return QMSClient(
            loadQMSList: {
                return QMSList(users: [])
            },
            loadQMSUser: { _ in
                return QMSUser(userId: 0, name: "", flag: 0, avatarUrl: nil, lastSeenOnline: .now, lastMessageDate: .now, unreadCount: 0, chats: [])
            },
            loadQMSChat: { id in
                return await mock.loadQMSChat()
            },
            sendQMSMessage: { chatId, message in
                return try await mock.sendQMSMessage(chatId: chatId, message: message)
            }
        )
    }
    
    // MARK: - Error On Send
    
    public static var errorOnSend: QMSClient {
        let mock = QMSClientMock(retries: 1)
        
        return QMSClient(
            loadQMSList: unimplemented(),
            loadQMSUser: unimplemented(),
            loadQMSChat: { id in
                return await mock.loadQMSChat()
            },
            sendQMSMessage: { chatId, message in
                return try await mock.sendQMSMessage(chatId: chatId, message: message)
            }
        )
    }
}

extension DependencyValues {
    public var qmsClient: QMSClient {
        get { self[QMSClient.self] }
        set { self[QMSClient.self] = newValue }
    }
}
