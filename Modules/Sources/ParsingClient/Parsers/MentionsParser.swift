//
//  MentionsParser.swift
//  ForPDA
//
//  Created by Codex on 19.02.2026.
//

import Foundation
import Models

public struct MentionsParser {
    public static func parse(from string: String) throws(ParsingError) -> Mentions {
        guard let data = string.data(using: .utf8) else {
            throw ParsingError.failedToCreateDataFromString
        }
        
        guard let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] else {
            throw ParsingError.failedToCastDataToAny
        }
        
        guard let (mentionsRaw, mentionsCount) = parsePayload(array) else {
            throw ParsingError.failedToCastFields
        }
        
        return Mentions(
            mentions: try parseMentions(mentionsRaw),
            mentionsCount: mentionsCount
        )
    }
    
    private static func parsePayload(_ array: [Any]) -> ([[Any]], Int)? {
        if let mentionsRaw = array[safe: 2] as? [[Any]],
           let mentionsCount = array[safe: 3] as? Int {
            return (mentionsRaw, mentionsCount)
        }
        
        if let mentionsCount = array[safe: 2] as? Int,
           let mentionsRaw = array[safe: 3] as? [[Any]] {
            return (mentionsRaw, mentionsCount)
        }
        
        return nil
    }
    
    private static func parseMentions(_ mentionsRaw: [[Any]]) throws(ParsingError) -> [Mention] {
        try mentionsRaw.map(parseMention)
    }
    
    private static func parseMention(_ mention: [Any]) throws(ParsingError) -> Mention {
        guard let typeRaw = mention[safe: 0] as? Int,
              let type = Mention.ContentType(rawValue: typeRaw),
              let isSeenRaw = mention[safe: 1] as? Int,
              let sourceId = mention[safe: 4] as? Int,
              let sourceName = (mention[safe: 5] as? String)?.convertCodes(),
              let targetId = mention[safe: 6] as? Int,
              let userId = mention[safe: 8] as? Int,
              let username = (mention[safe: 9] as? String)?.convertCodes(),
              let userGroupRaw = mention[safe: 10] as? Int,
              let userGroup = User.Group(rawValue: userGroupRaw),
              let lastSeenDateRaw = mention[safe: 11] as? TimeInterval,
              let reputationCount = mention[safe: 12] as? Int,
              let mentionDate = mention[safe: 13] as? TimeInterval,
              let userAvatarUrlRaw = mention[safe: 14] as? String else {
            throw ParsingError.failedToCastFields
        }
        
        return Mention(
            type: type,
            isSeen: isSeenRaw == 1,
            sourceId: sourceId,
            sourceName: sourceName,
            targetId: targetId,
            userId: userId,
            username: username,
            userGroup: userGroup,
            lastSeenDate: Date(timeIntervalSince1970: lastSeenDateRaw),
            reputationCount: reputationCount,
            mentionDate: Date(timeIntervalSince1970: mentionDate),
            userAvatarUrl: URL(string: userAvatarUrlRaw)
        )
    }
}
