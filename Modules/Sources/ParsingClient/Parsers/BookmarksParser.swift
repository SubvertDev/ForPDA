//
//  BookmarksParser.swift
//  ForPDA
//
//  Created by Xialtal on 30.11.24.
//

import Foundation
import Models

public struct BookmarksParser {
    public static func parse(from string: String) throws -> [Bookmark] {
        if let data = string.data(using: .utf8) {
            do {
                guard let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] else { throw ParsingError.failedToCastDataToAny }

                return (array[4] as! [[Any]]).map { bookmark in
                    return Bookmark(
                        id: bookmark[0] as! Int,
                        parentId: bookmark[4] as! Int,
                        name: bookmark[6] as! String,
                        number: bookmark[5] as! Int,
                        format: bookmarkFormat(bookmark),
                        updatedAt: Date(timeIntervalSince1970: bookmark[1] as! TimeInterval),
                        deleted: (bookmark[2] as! Int) == 0 ? false : true
                    )
                }
            } catch {
                throw ParsingError.failedToSerializeData(error)
            }
        } else {
            throw ParsingError.failedToCreateDataFromString
        }
    }
    
    private static func bookmarkFormat(_ array: [Any]) -> Bookmark.Format {
        return if (array[3] as! Int) == 1 { .folder } else {
            .url(url: URL(string: array[7] as! String)!)
        }
    }
}
