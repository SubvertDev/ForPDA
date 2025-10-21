//
//  File.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 19.10.2025.
//

import SwiftUI

public extension View {
    
    @available(iOS, deprecated: 17.0, message: "Use native contentMargins instead")
    func _contentMargins(_ edges: Edge.Set, _ length: CGFloat) -> some View {
        if #available(iOS 17, *) {
            return contentMargins(edges, length, for: .automatic)
        } else {
            return self
        }
    }
}
