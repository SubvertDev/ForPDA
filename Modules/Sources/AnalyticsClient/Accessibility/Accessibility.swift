//
//  Accessibility.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 07.03.2026.
//

import UIKit

public struct AccessibilityAnalyticsSnapshot: Encodable, Sendable {
    let voiceOverEnabled: Bool
    let switchControlEnabled: Bool
    let assistiveTouchEnabled: Bool
    let boldTextEnabled: Bool
    let reduceMotionEnabled: Bool
    let reduceTransparencyEnabled: Bool
    let differentiateWithoutColor: Bool
    let buttonShapesEnabled: Bool
    let invertColorsEnabled: Bool
    let preferredContentSizeCategory: String
    
    public func asDictionary() -> [String: Any] {
        let dictionary: [String: Any] = [
            "voice_over": voiceOverEnabled,
            "switch_control": switchControlEnabled,
            "assistive_touch": assistiveTouchEnabled,
            "bold_text": boldTextEnabled,
            "reduce_motion": reduceMotionEnabled,
            "reduce_transparency": reduceTransparencyEnabled,
            "differentiate_without_color": differentiateWithoutColor,
            "button_shapes": buttonShapesEnabled,
            "invert_colors": invertColorsEnabled,
            "content_size_category": preferredContentSizeCategory
        ]
        return ["accessibility": dictionary]
    }
}

public enum AccessibilityAnalytics {
    @MainActor public static func current(for traitCollection: UITraitCollection) -> AccessibilityAnalyticsSnapshot {
        AccessibilityAnalyticsSnapshot(
            voiceOverEnabled: UIAccessibility.isVoiceOverRunning,
            switchControlEnabled: UIAccessibility.isSwitchControlRunning,
            assistiveTouchEnabled: UIAccessibility.isAssistiveTouchRunning,
            boldTextEnabled: UIAccessibility.isBoldTextEnabled,
            reduceMotionEnabled: UIAccessibility.isReduceMotionEnabled,
            reduceTransparencyEnabled: UIAccessibility.isReduceTransparencyEnabled,
            differentiateWithoutColor: UIAccessibility.shouldDifferentiateWithoutColor,
            buttonShapesEnabled: UIAccessibility.buttonShapesEnabled,
            invertColorsEnabled: UIAccessibility.isInvertColorsEnabled,
            preferredContentSizeCategory: traitCollection.preferredContentSizeCategory.description
        )
    }
}

extension UIContentSizeCategory {
    var description: String {
        switch self {
        case .extraSmall:
            return "xs"
        case .small:
            return "s"
        case .medium:
            return "m"
        case .large:
            return "l"
        case .extraLarge:
            return "xl"
        case .extraExtraLarge:
            return "xxl"
        case .extraExtraExtraLarge:
            return "xxxl"
        case .accessibilityMedium:
            return "a-m"
        case .accessibilityLarge:
            return "a-l"
        case .accessibilityExtraLarge:
            return "a-xl"
        case .accessibilityExtraExtraLarge:
            return "a-xxl"
        case .accessibilityExtraExtraExtraLarge:
            return "a-xxxl"
        default:
            return "unknown"
        }
    }
}
