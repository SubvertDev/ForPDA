//
//  UserClient.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 16.08.2024.
//

import Foundation
import ComposableArchitecture
import Models

// TODO: Do I need it?
//public struct UserClient: Sendable {
//    public var startUserSession: @Sendable (_ userId: Int, _ token: String) async -> Void
//    public var endUserSession: @Sendable () async -> Void
//}
//
//extension UserClient: DependencyKey {
//    public static var liveValue: UserClient {
//        return UserClient(
//            startUserSession: { userId, token in
//                @Shared(.userSession) var userSession
//                await $userSession.withLock { $0 = UserSession(userId: userId, token: token) }
//            },
//            endUserSession: {
//                @Shared(.userSession) var userSession
//                await $userSession.withLock { $0 = nil }
//            }
//        )
//    }
//    
//    public static var previewValue: UserClient {
//        UserClient(
//            startUserSession: { _, _ in },
//            endUserSession: { }
//        )
//    }
//}
//
//extension DependencyValues {
//    public var userClient: UserClient {
//        get { self[UserClient.self] }
//        set { self[UserClient.self] = newValue }
//    }
//}

extension PersistenceKey where Self == PersistenceKeyDefault<FileStorageKey<UserSession?>> {
    public static var userSession: Self {
        return PersistenceKeyDefault(.fileStorage(.documentsDirectory.appending(component: "Session.json")), nil)
    }
}
