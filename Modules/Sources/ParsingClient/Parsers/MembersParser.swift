//
//  MembersParser.swift
//  ForPDA
//
//  Created by Рустам Ойтов on 29.10.2025.
//

import Foundation
import Models
import ComposableArchitecture

public struct MembersParser {
    
    // MARK: - parse
    
    public static func parse(from string: String) throws(ParsingError) -> MembersResponse {
        guard let data = string.data(using: .utf8) else {
            throw ParsingError.failedToCreateDataFromString
        }
        
        guard let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] else {
            throw ParsingError.failedToCastDataToAny
        }
        
        guard let meta0 = array[safe: 0] as? Int,
              let meta1 = array[safe: 1] as? Int,
              let meta2 = array[safe: 2] as? Int,
              let membersArray = array[safe: 3] as? [[Any]] else {
            throw ParsingError.failedToCastFields
        }
        
        return MembersResponse(
            metadata: [meta0, meta1, meta2],
            members: try parseMembers(membersArray)
        )
    }
    
    // MARK: - parse members
    
    private static func parseMembers(_ rawMembers: [[Any]]) throws(ParsingError) -> [Member] {
        var members: [Member] = []
        
        for memberRaw in rawMembers {
            guard let id = memberRaw[safe: 0] as? Int,
                  let name = memberRaw[safe: 1] as? String,
                  let groupId = memberRaw[safe: 2] as? Int,
                  let avatarUrl = memberRaw[safe: 3] as? String else {
                throw ParsingError.failedToCastFields
            }
            
            let member = Member(
                id: id,
                nickname: name.convertCodes(),
                unknown3: groupId,
                avatarUrl: avatarUrl
            )
            members.append(member)
        }
        return members
    }
}
