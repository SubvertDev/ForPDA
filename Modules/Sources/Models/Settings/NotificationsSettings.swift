//
//  NotificationsSettings.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 17.11.2024.
//

public struct NotificationsSettings2: OptionSet, Sendable, Codable, Hashable {
    
    public var rawValue: Int
    
    public var isAnyEnabled: Bool {
        return !isEmpty
    }
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let qms                = NotificationsSettings2(rawValue: 1 << 0)
    public static let qmsSystemEvents    = NotificationsSettings2(rawValue: 1 << 1)
    public static let favorites          = NotificationsSettings2(rawValue: 1 << 2)
    public static let favoritesImportant = NotificationsSettings2(rawValue: 1 << 3)
    public static let mentions           = NotificationsSettings2(rawValue: 1 << 4)
}

extension NotificationsSettings2 {
    public enum FavoritesMode: String, CaseIterable, Identifiable, Sendable, Codable {
        public var id: String { rawValue }
        case all
        case important
        case disabled
    }

    private static let favoritesMask: Self = [
        .favorites,
        .favoritesImportant
    ]

    public var favoritesMode: FavoritesMode {
        get {
            switch (
                contains(.favorites),
                contains(.favoritesImportant)
            ) {
            case (true, false):
                return .all

            case (false, true):
                return .important

            case (false, false):
                return .disabled

            case (true, true):
                assertionFailure("Invalid favorites notification flags")
                return .all
            }
        }

        set {
            remove(Self.favoritesMask)

            switch newValue {
            case .all:
                insert(.favorites)

            case .important:
                insert(.favoritesImportant)

            case .disabled:
                break
            }
        }
    }
}

extension NotificationsSettings2 {
    static let `default`: NotificationsSettings2 = [
        .qms,
        .qmsSystemEvents,
        .favorites,
        .mentions
    ]
}
