//
//  HapticClient.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 14.09.2024.
//

import UIKit
import ComposableArchitecture

// TODO: I don't think I need this as a dependency

public enum HapticType: Sendable {
    case success
    case warning
    case error
    
    case light
    case medium
    case heavy
    
    case rigid
    case soft
    case selection
}

@DependencyClient
public struct HapticClient: Sendable {
    public var play: @Sendable (_ type: HapticType) async -> Void
}

public extension DependencyValues {
    var hapticClient: HapticClient {
        get { self[HapticClient.self] }
        set { self[HapticClient.self] = newValue }
    }
}

extension HapticClient: DependencyKey {
    public static let liveValue = Self(
        play: { type in
            switch type {
            case .success:
                await UINotificationFeedbackGenerator()
                    .notificationOccurred(.success)
                
            case .warning:
                await UINotificationFeedbackGenerator()
                    .notificationOccurred(.warning)
                
            case .error:
                await UINotificationFeedbackGenerator()
                    .notificationOccurred(.error)

            case .light:
                await UIImpactFeedbackGenerator(style: .light)
                    .impactOccurred(intensity: 1.0)

            case .medium:
                await UIImpactFeedbackGenerator(style: .medium)
                    .impactOccurred(intensity: 1.0)

            case .heavy:
                await UIImpactFeedbackGenerator(style: .heavy)
                    .impactOccurred(intensity: 1.0)

            case .rigid:
                await UIImpactFeedbackGenerator(style: .rigid)
                    .impactOccurred(intensity: 1.0)

            case .soft:
                await UIImpactFeedbackGenerator(style: .soft)
                    .impactOccurred(intensity: 1.0)
                
            case .selection:
                await UISelectionFeedbackGenerator()
                    .selectionChanged()
            }
        }
    )
    
    public static let testValue = Self(
        play: { _ in }
    )
}
