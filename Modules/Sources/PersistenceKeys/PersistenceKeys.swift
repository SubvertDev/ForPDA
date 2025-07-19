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

extension SharedKey where Self == FileStorageKey<UserSession?>.Default {
    public static var userSession: Self {
        return Self[.fileStorage(.documentsDirectory.appending(component: "Session.json")), default: nil]
    }
}

// MARK: - App Settings

extension SharedReaderKey where Self == FileStorageKey<AppSettings>.Default {
    public static var appSettings: Self {
        let url = URL.documentsDirectory.appending(component: "Settings.json")
        return Self[.fileStorage(url), default: AppSettings.default]
    }
}
