//
//  Backport.swift
//  SharedUI
//
//  Created by subvert on 03.10.2026.
//

import SwiftUI

public struct Backport<Content> {
    let content: Content
}

extension View {
    public var backport: Backport<Self> {
        Backport(content: self)
    }
}

// MARK: - scrollBounceBehavior

extension Backport where Content: View {
    
    public enum ScrollBounceBehavior {
        case always
        case automatic
        case basedOnSize
        
        @available(iOS 16.4, *)
        func backported() -> SwiftUI.ScrollBounceBehavior {
            switch self {
            case .always:      return .always
            case .automatic:   return .automatic
            case .basedOnSize: return .basedOnSize
            }
        }
    }
    
    @ContentBuilder
    public func scrollBounceBehavior(_ behavior: ScrollBounceBehavior, axes: Axis.Set = [.vertical]) -> some View {
        if #available(iOS 16.4, *) {
            content
                .scrollBounceBehavior(behavior.backported(), axes: axes)
        } else {
            content
        }
    }
}

// MARK: - presentationBackgroundInteraction

extension Backport where Content: View {
    
    public struct PresentationBackgroundInteraction: Sendable {
        enum Value: Sendable {
            case automatic
            case enabled
            case enabledUpThrough(PresentationDetent)
            case disabled
        }

        let value: Value

        public static var automatic: Self {
            .init(value: .automatic)
        }

        public static var enabled: Self {
            .init(value: .enabled)
        }

        public static func enabled(upThrough detent: PresentationDetent) -> Self {
            .init(value: .enabledUpThrough(detent))
        }

        public static var disabled: Self {
            .init(value: .disabled)
        }
        
        @available(iOS 16.4, *)
        func backported() -> SwiftUI.PresentationBackgroundInteraction {
            switch value {
            case .automatic:
                return .automatic
            case .enabled:
                return .enabled
            case .enabledUpThrough(let presentationDetent):
                return .enabled(upThrough: presentationDetent)
            case .disabled:
                return .disabled
            }
        }
    }
    
    @ContentBuilder
    public func presentationBackgroundInteraction(_ interaction: PresentationBackgroundInteraction) -> some View {
        if #available(iOS 16.4, *) {
            content
                .presentationBackgroundInteraction(interaction.backported())
        } else {
            content
        }
    }
}
