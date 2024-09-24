//
//  String+Ext.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 29.07.2024.
//

import Foundation

extension String {
    /// Mostly used to decode specific symbols like emojis
    func convertHtmlCodes() -> String {
        var text = self
        // raw html parse loses \n\t that are used in article tables
        text = text.replacingOccurrences(of: "\\n\\t", with: "/n/t", options: .regularExpression)
        // raw html parse loses \r\n that are used in article comments
        text = text.replacingOccurrences(of: "\\r\\n\\s*", with: "/r/n", options: .regularExpression)
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
}
