//
//  SharedUI.swift
//  
//
//  Created by Ilia Lubianoi on 12.05.2024.
//

import SwiftUI
import RswiftResources

// MARK: - Images

public extension Image {
    
    static func shared(_ resource: RswiftResources.ImageResource) -> Image {
        .init(resource)
    }
    
    init(_ resource: RswiftResources.ImageResource) {
        self.init(resource.name)
    }
}

// MARK: - Fonts

//extension RswiftResources.FontResource {
//    func wrapped(size: CGFloat) -> Font {
//        Font.custom(name, size: size)
//    }
//}

// MARK: - Colors

//extension RswiftResources.ColorResource {
//    var asColor: Color {
//        Color(name)
//    }
//}
