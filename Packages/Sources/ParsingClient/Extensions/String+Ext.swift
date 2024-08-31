//
//  String+Ext.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 29.07.2024.
//

import Foundation

extension String {
    func convertHtmlCodes() -> String {
        let attributedString = try! NSAttributedString(
            data: Data(utf8),
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        )
        return attributedString.string
    }
}
