//
//  NotificationService.swift
//  NotificationServiceExtension
//
//  Created by Xialtal on 10.07.26.
//

import UserNotifications
import NotificationsClient
import Models

class NotificationService: UNNotificationServiceExtension {
    
    private let manager = NotificationManager()
    private let delivery = NotificationDelivery()
    
    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        guard let mutableContent = request.content.mutableCopy() as? UNMutableNotificationContent else {
            contentHandler(request.content)
            return
        }
        
        delivery.prepare(content: mutableContent, handler: contentHandler)
        
        guard let notification = PDANotification(userInfo: request.content.userInfo) else {
            delivery.finish()
            return
        }
        
        let delivery = delivery
        let manager = manager
        let originalIdentifier = request.identifier
        
        Task {
            let content = await manager.handlePushNotification(item: notification)
            
            switch content {
            case .deliver(let title, let body):
                delivery.update(interruptionLevel: .active, sound: .default)
                delivery.finish(title: title, body: body)
                
            case .suppress:
                delivery.update(interruptionLevel: .passive, sound: nil)
                delivery.finish()

                try? await Task.sleep(for: .seconds(0.1))
                
                let identifiers = await UNUserNotificationCenter.current()
                    .deliveredNotifications()
                    .filter { $0.request.identifier == originalIdentifier }
                    .map(\.request.identifier)
                
                UNUserNotificationCenter.current()
                    .removeDeliveredNotifications(withIdentifiers: identifiers)
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        delivery.finish()
    }
}

// MARK: - Delivery

private final class NotificationDelivery: @unchecked Sendable {

    typealias Handler = (UNNotificationContent) -> Void

    private let lock = NSLock()

    private var content: UNMutableNotificationContent?
    private var handler: Handler?

    func prepare(
        content: UNMutableNotificationContent,
        handler: @escaping Handler
    ) {
        lock.lock()
        self.content = content
        self.handler = handler
        lock.unlock()
    }
    
    func update(
        interruptionLevel: UNNotificationInterruptionLevel,
        sound: UNNotificationSound?
    ) {
        content?.interruptionLevel = interruptionLevel
        content?.sound = sound
    }

    func finish(
        title: String? = nil,
        body: String? = nil
    ) {
        let result: (
            handler: Handler,
            content: UNNotificationContent
        )?

        lock.lock()

        if let content, let handler {
            if let title {
                content.title = title
            }

            if let body {
                content.body = body
            }

            // Clear these before invoking the callback so only one caller can deliver the notification
            self.content = nil
            self.handler = nil

            result = (handler, content)
        } else {
            result = nil
        }

        lock.unlock()

        // Never invoke external code while holding the lock
        if let result {
            result.handler(result.content)
        }
    }
}
