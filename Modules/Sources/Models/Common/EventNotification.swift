//
//  EventNotification.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 05.10.2025.
//

public struct EventNotification {
    public let id: Int
    public let category: Category
    public let flag: Int
    public let timestamp: Int
    
    public enum Category: String {
        case qms = "q"
        case topic = "t"
        case site = "s"
        case forum = "f"
        // case u?
        // case g?
        case unknown
    }
    
    public init(
        id: Int,
        category: Category,
        flag: Int,
        timestamp: Int
    ) {
        self.id = id
        self.category = category
        self.flag = flag
        self.timestamp = timestamp
    }
}
