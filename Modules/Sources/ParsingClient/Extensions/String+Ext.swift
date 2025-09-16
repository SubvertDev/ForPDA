//
//  String+Ext.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 29.07.2024.
//

import Foundation

extension String {
    /// Mostly used to decode specific symbols like emojis
    // TODO: Revisit
    func convertHtmlCodes() -> String {
        var text = self
        // raw html parse loses \n\t that are used in article tables
        text = text.replacingOccurrences(of: "\\n\\t", with: "/n/t", options: .regularExpression)
        // raw html parse loses \r\n that are used in article comments
        text = text.replacingOccurrences(of: "\\r\\n", with: "/r/n", options: .regularExpression)
        text = text.fixSurrogatePairs()
        let attributedString = try! NSAttributedString(
            data: Data(text.utf8),
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        )
        var editedString = attributedString.string
        editedString = editedString.replacingOccurrences(of: "/n/t", with: "\n")
        editedString = editedString.replacingOccurrences(of: "/r/n", with: "\r\n")
        return editedString
    }
    
    public func convertCodes() -> String {
        BBCodeParser.fastParse(self)
    }
}

extension String {
    func fixSurrogatePairs() -> String {
        let regex = try! NSRegularExpression(pattern: #"&#(\d+);&#(\d+);"#)
        var newText = self
        let matches = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))

        for match in matches.reversed() {
            if let highRange = Range(match.range(at: 1), in: self),
               let lowRange = Range(match.range(at: 2), in: self),
               let high = Int(self[highRange]),
               let low = Int(self[lowRange]),
               (0xD800...0xDBFF).contains(high),
               (0xDC00...0xDFFF).contains(low) {
                
                let scalar = 0x10000 + ((high - 0xD800) << 10) + (low - 0xDC00)
                let replacement = "&#\(scalar);"
                newText.replaceSubrange(self.index(highRange.lowerBound, offsetBy: -2)..<self.index(after: lowRange.upperBound), with: replacement)
            }
        }
        return newText
    }
}
