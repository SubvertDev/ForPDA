//
//  QMSClientMock.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 28.11.2025.
//

import ComposableArchitecture
import Foundation
import Models
import NotificationsClient

actor QMSClientMock {
    
    // MARK: - Properties
    
    static let senderId = 1
    static let partnerId = 2
    
    var messages: [QMSMessage] = [.mock(), .mock()]
    var unreadCount = 1
    
    var waitingTask: Task<Void, Never>?
    var retries: Int
    
    // MARK: - Dependencies
    
    @Dependency(\.notificationsClient) var notificationsClient
    
    // MARK: - Init
    
    init(retries: Int = 0) {
        self.retries = retries
    }
    
    // MARK: - Interface
    
    func sendQMSMessage(chatId: Int, message: String) async throws {
        if retries != 0 {
            retries -= 1
            try? await Task.sleep(for: .seconds(1))
            throw NSError(domain: "mock", code: 0)
        }
        
        waitingTask?.cancel()
        waitingTask = nil
        
        var notification = ""
        waitingTask = Task {
            try? await Task.sleep(for: .seconds(3))
            if Task.isCancelled { return }
            unreadCount = 0
            notification = "[0,0,\"q\(chatId)\",102,\(Int(Date().timeIntervalSince1970))]"
            _ = await notificationsClient.processNotification(notification)

            try? await Task.sleep(for: .seconds(3))
            if Task.isCancelled { return }
            messages.append(makePartnerMessage())
            notification = "[0,0,\"q\(chatId)\",102,\(Int(Date().timeIntervalSince1970))]"
            _ = await notificationsClient.processNotification(notification)
        }
        
        let qmsMessage = QMSMessage(
            id: Int.random(in: 0...1000000),
            senderId: QMSClientMock.senderId,
            date: .now,
            text: message,
            attachments: []
        )
        messages.append(qmsMessage)
        unreadCount += 1
        
        notification = "[0,0,\"q\(chatId)\",102,\(Int(Date().timeIntervalSince1970))]"
        _ = await notificationsClient.processNotification(notification)
    }
    
    func loadQMSChat() async -> QMSChat {
        try? await Task.sleep(for: .seconds(1))
        return QMSChat(
            id: 0,
            creationDate: Date(timeIntervalSince1970: 1234567890),
            lastMessageDate: messages.last?.date ?? Date(),
            name: "Test Chat",
            partnerId: QMSClientMock.partnerId,
            partnerName: "Partner",
            flag: 0,
            avatarUrl: nil,
            unknownId1: 0,
            totalCount: messages.count,
            unknownId2: 0,
            lastMessageId: messages.last?.id ?? 0,
            unreadCount: unreadCount,
            messages: messages
        )
    }
    
    // MARK: - Private
    
    private func makePartnerMessage() -> QMSMessage {
        return QMSMessage(
            id: Int.random(in: -1000000...0),
            senderId: QMSClientMock.partnerId,
            date: .now,
            text: "ok",
            attachments: []
        )
    }
}
