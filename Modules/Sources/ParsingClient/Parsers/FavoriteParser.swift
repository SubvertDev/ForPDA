//
//  FavoriteParser.swift
//  ForPDA
//
//  Created by Xialtal on 8.11.24.
//

import Foundation
import Models

public struct FavoriteParser {
    public static func parse(from string: String) throws -> Favorite {
        if let data = string.data(using: .utf8) {
            do {
                guard let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] else { throw ParsingError.failedToCastDataToAny }

                return Favorite(
                    favorites: parseFavorites(array[3] as! [[Any]]),
                    favoritesCount: array[2] as! Int
                )
            } catch {
                throw ParsingError.failedToSerializeData(error)
            }
        } else {
            throw ParsingError.failedToCreateDataFromString
        }
    }
    
    private static func parseFavorites(_ array: [[Any]]) -> [FavoriteInfo] {
        return array.map { favorite in
            return FavoriteInfo(
                flag: favorite[11] as! Int,
                topic: TopicInfo(
                    id: favorite[1] as! Int,
                    name: (favorite[2] as! String).convertCodes(),
                    description: (favorite[3] as! String).convertCodes(),
                    flag: favorite[4] as! Int,
                    postsCount: favorite[10] as! Int,
                    lastPost: TopicInfo.LastPost(
                        date: Date(timeIntervalSince1970: favorite[9] as! TimeInterval),
                        userId: favorite[7] as! Int,
                        username: (favorite[8] as! String).convertCodes()
                    )
                ),
                isForum: favorite[0] as! Int == 0 ? true : false
            )
        }
    }
}
