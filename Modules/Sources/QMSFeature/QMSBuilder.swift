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
    
    // TODO: Change to full BBBuilder with container nodes later
    public func build() -> AttributedString {
        let renderedText = BBRenderer().render(text: text)
        let result = NSMutableAttributedString(attributedString: renderedText)
        
        let pattern = #"\[attachment=([^,\]]+),(\d+)\]"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])

        let fullRange = NSRange(location: 0, length: result.length)
        let matches = regex.matches(in: result.string, options: [], range: fullRange).reversed()
        
        for match in matches {
            guard
                match.numberOfRanges == 3,
                let nameRange = Range(match.range(at: 1), in: result.string),
                let idRange = Range(match.range(at: 2), in: result.string)
            else { continue }

            let fileName = String(result.string[nameRange])
            let attachmentID = String(result.string[idRange])

            let linkText = NSMutableAttributedString(string: fileName)
            linkText.addAttribute(.link, value: "link://\(attachmentID)", range: NSRange(location: 0, length: fileName.count))

            result.replaceCharacters(in: match.range, with: linkText)
        }
        
        return AttributedString(result)
    }
}
