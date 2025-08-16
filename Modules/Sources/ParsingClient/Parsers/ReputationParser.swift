//
//  ReputationParser.swift
//  ForPDA
//
//  Created by Xialtal on 12.04.25.
//

import Foundation
import Models

public struct ReputationParser {
    
    // MARK: - Reputation Votes
    
    public static func parse(from string: String) throws(ParsingError) -> ReputationVotes {
        guard let data = string.data(using: .utf8) else {
            throw ParsingError.failedToCreateDataFromString
        }
        
        guard let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] else {
            throw ParsingError.failedToCastDataToAny
        }
        
        guard let votesCount = array[safe: 2] as? Int,
              let votes = array[safe: 3] as? [[Any]] else {
            throw ParsingError.failedToCastFields
        }
        
        return ReputationVotes(
            votes: try parseVotes(votes),
            votesCount: votesCount
        )
    }
    
    // MARK: - Favorites
    
    private static func parseVotes(_ votesRaw: [[Any]]) throws(ParsingError)-> [ReputationVote] {
        var votes: [ReputationVote] = []
        for vote in votesRaw {
            guard let id = vote[safe: 0] as? Int,
                  let flag = vote[safe: 6] as? Int,
                  let toId = vote[safe: 3] as? Int,
                  let toName = vote[safe: 5] as? String,
                  let authorId = vote[safe: 2] as? Int,
                  let authorName = vote[safe: 4] as? String,
                  let reason = vote[safe: 10] as? String,
                  let createdAt = vote[safe: 1] as? TimeInterval else {
                throw ParsingError.failedToCastFields
            }
            
            let vote = ReputationVote(
                id: id,
                flag: flag,
                toId: toId,
                toName: toName,
                authorId: authorId,
                authorName: authorName,
                reason: reason.convertHtmlCodes(),
                modified: try parseVoteModified(vote, flag),
                createdIn: try parseVoteCreatedIn(vote),
                createdAt: Date(timeIntervalSince1970: createdAt),
                isDown: flag & 1 == 0
            )
            votes.append(vote)
        }
        return votes
    }
    
    // MARK: - Vote Modified
    
    private static func parseVoteModified(_ vote: [Any], _ flag: Int) throws(ParsingError) -> ReputationVote.VoteModified? {
        if vote[safe: 11] as? Int == 0 {
            return nil
        }
        
        guard let userId = vote[safe: 12] as? Int,
              let userName = vote[safe: 13] as? String else {
            throw ParsingError.failedToCastFields
        }
       
        return ReputationVote.VoteModified(
            userId: userId,
            userName: userName,
            isDenied: flag & 2 != 0
        )
    }
    
    // MARK: - Vote Created In
    
    private static func parseVoteCreatedIn(_ vote: [Any]) throws(ParsingError) -> ReputationVote.VoteCreatedIn {
        guard let mainId = vote[safe: 7] as? Int,
              let mainName = vote[safe: 8] as? String,
              let id = vote[safe: 9] as? Int else {
            throw ParsingError.failedToCastFields
        }
        
        return if mainId == 0 { .profile } else {
            if id > 0 {
                .topic(id: mainId, topicName: mainName, postId: id)
            } else {
                .site(id: mainId, articleName: mainName, commentId: abs(id))
            }
        }
    }
}
