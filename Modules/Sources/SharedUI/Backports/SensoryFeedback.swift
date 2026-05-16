//
//  SensoryFeedback.swift
//  SharedUI
//
//  Created by Ilia Lubianoi on 16.05.2026.
//

import SwiftUI

public enum _SensoryFeedback {
    
    case impactLight
    case success
    case error
    
    @available(iOS 17, *)
    var converted: SensoryFeedback {
        switch self {
        case .impactLight:
            return .impact(weight: .light)
        case .success:
            return .success
        case .error:
            return .error
        }
    }
}

public extension View {
    
    @ViewBuilder
    func _sensoryFeedback(_ feedback: _SensoryFeedback, trigger: some Equatable) -> some View {
        if #available(iOS 17, *) {
            self.sensoryFeedback(feedback.converted, trigger: trigger)
        } else {
            self
        }
    }
}
