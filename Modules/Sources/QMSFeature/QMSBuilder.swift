//
//  QMSBuilder.swift
//  QMSFeature
//
//  Created by Ilia Lubianoi on 24.10.2025.
//

import BBBuilder
import Foundation
import Models

public struct QMSBuilder {
    
    private let text: String
    
    public init(text: String) {
        self.text = text
    }
    
    public func build() -> AttributedString {
        let renderedText = BBRenderer().render(text: text)
        return AttributedString(renderedText)
    }
}
