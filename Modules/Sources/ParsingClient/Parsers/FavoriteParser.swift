//
//  FavoriteParser.swift
//  ForPDA
//
//  Created by Xialtal on 8.11.24.
//

import Foundation
import Models

public struct FavoriteParser {
    
    // MARK: - Favorite
    
    public static func parse(from string: String) throws(ParsingError) -> Favorite {
        guard let data = string.data(using: .utf8) else {
            throw ParsingError.failedToCreateDataFromString
        }
        
        guard let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] else {
            throw ParsingError.failedToCastDataToAny
        }
        
        guard let favoritesCount = array[safe: 2] as? Int,
              let favorites = array[safe: 3] as? [[Any]] else {
            throw ParsingError.failedToCastFields
        }
        
        return Favorite(
            favorites: try parseFavorites(favorites),
            favoritesCount: favoritesCount
        )
    }
    
    // MARK: - Favorites
    
    private static func parseFavorites(_ favoritesRaw: [[Any]]) throws(ParsingError)-> [FavoriteInfo] {
        var favorites: [FavoriteInfo] = []
        for favorite in favoritesRaw {
            guard let isForum = favorite[safe: 0] as? Int,
                  let id = favorite[safe: 1] as? Int,
                  let name = favorite[safe: 2] as? String,
                  let description = favorite[safe: 3] as? String,
                  let topicFlag = favorite[safe: 4] as? Int,
                  let userId = favorite[safe: 7] as? Int,
                  let username = favorite[safe: 8] as? String,
                  let date = favorite[safe: 9] as? TimeInterval,
                  let postsCount = favorite[safe: 10] as? Int,
                  let flag = favorite[safe: 11] as? Int else {
                throw ParsingError.failedToCastFields
            }
            
            let favorite = FavoriteInfo(
                flag: flag,
                topic: TopicInfo(
                    id: id,
                    name: name.convertCodes(),
                    description: description.convertCodes(),
                    flag: topicFlag,
                    postsCount: postsCount,
                    lastPost: TopicInfo.LastPost(
                        date: Date(timeIntervalSince1970: date),
                        userId: userId,
                        username: username.convertCodes()
                    )
                ),
                isForum: isForum == 0 ? true : false
            )
            favorites.append(favorite)
        }
        return favorites
    }
}
