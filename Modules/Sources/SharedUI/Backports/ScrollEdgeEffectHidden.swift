//
//  ScrollEdgeEffectHidden.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 26.10.2025.
//

import SwiftUI

public extension View {
    
    @available(iOS, deprecated: 26, message: "Use native scrollEdgeEffectHidden instead")
    func _scrollEdgeEffectHidden(_ hidden: Bool, for edges: Edge.Set = .all) -> some View {
        if #available(iOS 26, *) {
            return scrollEdgeEffectHidden(hidden, for: edges)
        } else {
            return self
        }
    }
}
