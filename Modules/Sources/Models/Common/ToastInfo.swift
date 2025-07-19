//
//  ToastInfo.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 23.08.2024.
//

import SwiftUI

public struct ToastInfo: Equatable, @unchecked Sendable {
    
    public let screen: ToastScreen
    public let message: LocalizedStringKey
    public let isError: Bool
    
    @available(*, deprecated, message: "Use `ToastMessage` instead.")
    public init(
        screen: ToastScreen,
        message: LocalizedStringKey,
        isError: Bool = false
    ) {
        self.screen = screen
        self.message = message
        self.isError = isError
    }
    
    @_disfavoredOverload
    public init(
        screen: ToastScreen,
        message: String,
        isError: Bool = false
    ) {
        self.screen = screen
        self.message = LocalizedStringKey(message)
        self.isError = isError
    }
}

public enum ToastScreen: Equatable, Sendable {
    case app
    case articlesList
    case article
    case comments
    case favorites
}
