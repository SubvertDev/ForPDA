//
//  ToastInfo.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 23.08.2024.
//

import SwiftUI

public struct ToastInfo: Equatable {
    public let screen: ToastScreen
    public let message: LocalizedStringKey
    public let isError: Bool
    
    public init(
        screen: ToastScreen,
        message: LocalizedStringKey,
        isError: Bool
    ) {
        self.screen = screen
        self.message = message
        self.isError = isError
    }
    
    @_disfavoredOverload
    public init(
        screen: ToastScreen,
        message: String,
        isError: Bool
    ) {
        self.screen = screen
        self.message = LocalizedStringKey(message)
        self.isError = isError
    }
}

public enum ToastScreen: Equatable {
    case articlesList
    case article
    case comments
    case favorites
}
