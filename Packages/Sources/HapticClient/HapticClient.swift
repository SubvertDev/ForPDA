//
//  HapticClient.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 14.09.2024.
//

import UIKit
import ComposableArchitecture

public enum HapticType {
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
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
            case .warning:
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
                
            case .error:
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)

            case .light:
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred(intensity: 1.0)

            case .medium:
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred(intensity: 1.0)

            case .heavy:
                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.impactOccurred(intensity: 1.0)

            case .rigid:
                let generator = UIImpactFeedbackGenerator(style: .rigid)
                generator.impactOccurred(intensity: 1.0)

            case .soft:
                let generator = UIImpactFeedbackGenerator(style: .soft)
                generator.impactOccurred(intensity: 1.0)
                
            case .selection:
                let generator = UISelectionFeedbackGenerator()
                generator.selectionChanged()
            }
        }
    )
    
    public static let testValue = Self(
        play: { _ in }
    )
}
