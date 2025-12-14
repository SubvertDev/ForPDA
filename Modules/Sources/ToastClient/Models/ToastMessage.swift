//
//  ToastMessage.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 27.09.2025.
//

import Foundation
import HapticClient

public struct ToastMessage: Equatable, Sendable {
    
    public enum Priority: Int, Comparable, Sendable {
        case low = 0
        // case medium = 1
        case high = 2
        
        public static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
    
    public let text: LocalizedStringResource
    public let isError: Bool
    public let haptic: HapticType?
    public let duration: Int
    public let priority: Priority
    
    public init(
        text: LocalizedStringResource,
        isError: Bool = false,
        haptic: HapticType? = nil,
        duration: Int = 3,
        priority: Priority = .low
    ) {
        self.text = text
        self.isError = isError
        self.haptic = haptic
        self.duration = duration
        self.priority = priority
    }
}

public extension ToastMessage {
    static let actionCompleted = ToastMessage(
        text: LocalizedStringResource("Action completed", bundle: .module),
        isError: false,
        haptic: .success,
        duration: 3,
        priority: .low
    )
    
    static let whoopsSomethingWentWrong = ToastMessage(
        text: LocalizedStringResource("Whoops, something went wrong..", bundle: .module),
        isError: true,
        haptic: .error,
        duration: 3,
        priority: .low // .high?
    )
}
