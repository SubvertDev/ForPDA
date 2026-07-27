//
//  NotificationService.swift
//  NotificationServiceExtension
//
//  Created by Xialtal on 10.07.26.
//

import UserNotifications
import Models
import ParsingClient

class NotificationService: UNNotificationServiceExtension {
    
    // MARK: - Properties
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    // MARK: - Logic
    
    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent,
           let rawCategory = request.content.userInfo["t"] as? Int,
           let category = Unread.Item.Category(rawValue: rawCategory),
           let subjectRootId = request.content.userInfo["i"] as? Int,
           let subjectRootTitle = request.content.userInfo["n"] as? String,
           let authorName = request.content.userInfo["an"] as? String,
           let subjectId = request.content.userInfo["v"] as? Int {
            let optional = Int(request.content.userInfo["e1"] as? String ?? "0")
            let notification = buildNotification(category, subjectRootTitle.convertCodes(), authorName.convertCodes(), optional)
            bestAttemptContent.title = notification.0
            bestAttemptContent.body = notification.1
            bestAttemptContent.userInfo = [
                "t": rawCategory,
                "i": subjectRootId,
                "v": subjectId
            ]
            
            contentHandler(bestAttemptContent)
        }
    }
    
    private func buildNotification(
        _ category: Unread.Item.Category,
        _ subjectRootTitle: String,
        _ authorName: String,
        _ optional: Int?
    ) -> (String, String) {
        return switch category {
        case .qms: (authorName, "\(subjectRootTitle): \(optional!) новое сообщение")
        case .forum: ("Новое на форуме", subjectRootTitle)
        case .topic: (optional! & 4 != 0 ? "Обновилась шапка" : "\(authorName) в теме", subjectRootTitle)
        case .forumMention: ("Упоминание в теме \(subjectRootTitle)", "\(authorName) ссылается на вас")
        case .siteMention: ("Упоминание в новости \(subjectRootTitle)", "\(authorName) ссылается на вас")
        }
    }
}
