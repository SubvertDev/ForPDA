//
//  MembersParser.swift
//  ForPDA
//
//  Created by Рустам Ойтов on 29.10.2025.
//

import Foundation
import Models

public struct SearchUsersParser {
    
    // MARK: - Parse
    
    public static func parse(from string: String) throws(ParsingError) -> SearchUsersResponse {
        guard let data = string.data(using: .utf8) else {
            throw ParsingError.failedToCreateDataFromString
        }
        
        guard let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] else {
            throw ParsingError.failedToCastDataToAny
        }
        
        guard let usersCount = array[safe: 2] as? Int,
              let usersRaw = array[safe: 3] as? [[Any]] else {
            throw ParsingError.failedToCastFields
        }
        
        return SearchUsersResponse(
            users: try parseUsers(usersRaw),
            usersCount: usersCount
        )
    }
    
    // MARK: - Parse Users
    
    private static func parseUsers(_ rawMembers: [[Any]]) throws(ParsingError) -> [SearchUsersResponse.SimplifiedUser] {
        var members: [SearchUsersResponse.SimplifiedUser] = []
        
        for memberRaw in rawMembers {
            guard let id = memberRaw[safe: 0] as? Int,
                  let name = memberRaw[safe: 1] as? String,
                  let groupId = memberRaw[safe: 2] as? Int,
                  let avatarUrl = memberRaw[safe: 3] as? String else {
                throw ParsingError.failedToCastFields
            }
            
            let user = SearchUsersResponse.SimplifiedUser(
                id: id,
                name: name,
                groupId: groupId,
                avatarUrl: avatarUrl
            )
            members.append(user)
        }
        return members
    }
}
