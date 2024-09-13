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
    
    public init (
        screen: ToastScreen,
        message: LocalizedStringKey
    ) {
        self.screen = screen
        self.message = message
    }
    
    public init(
        screen: ToastScreen,
        message: String
    ) {
        self.screen = screen
        self.message = LocalizedStringKey(message)
    }
}

public enum ToastScreen: Equatable {
    case articlesList
    case article
}
