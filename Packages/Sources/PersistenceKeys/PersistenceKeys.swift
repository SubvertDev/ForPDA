//
//  UserClient.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 16.08.2024.
//

import Foundation
import ComposableArchitecture
import Models

// MARK: - User Session

extension PersistenceKey where Self == PersistenceKeyDefault<FileStorageKey<UserSession?>> {
    public static var userSession: Self {
        return PersistenceKeyDefault(.fileStorage(.documentsDirectory.appending(component: "Session.json")), nil)
    }
}

// MARK: - App Settings

extension PersistenceReaderKey where Self == PersistenceKeyDefault<FileStorageKey<AppSettings>> {
    public static var appSettings: Self {
        let url = URL.documentsDirectory.appending(component: "Settings.json")
        return PersistenceKeyDefault(.fileStorage(url), AppSettings.default)
    }
}
