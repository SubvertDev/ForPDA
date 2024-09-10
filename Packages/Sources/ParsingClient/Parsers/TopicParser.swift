//
//  TopicParser.swift
//  ForPDA
//
//  Created by Xialtal on 7.09.24.
//

import Foundation
import Models

public struct TopicParser {
    public static func parse(rawString string: String) throws -> Topic {
        if let data = string.data(using: .utf8) {
            do {
                guard let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] else { throw ParsingError.failedToCastDataToAny }
                return Topic(
                    id: array[3] as! Int,
                    name: array[4] as! String,
                    description: array[5] as! String,
                    flag: array[6] as! Int,
                    createdAt: Date(timeIntervalSince1970: array[7] as! TimeInterval),
                    authorId: array[8] as! Int,
                    authorName: array[9] as! String,
                    curatorId: array[10] as! Int,
                    curatorName: array[11] as! String,
                    poll: parsePoll(array[12] as! [Any]),
                    postsCount: array[13] as! Int,
                    posts: parsePost(array[14] as! [[Any]]),
                    navigation: ForumParser.parseNavigation(array[2] as! [[Any]])
                )
            } catch {
                throw ParsingError.failedToSerializeData(error)
            }
        } else {
            throw ParsingError.failedToCreateDataFromString
        }
    }
    
    private static func parsePoll(_ array: [Any]) -> Optional<Topic.Poll> {
        return if !array.isEmpty {
            Optional.some(Topic.Poll(
                name: array[0] as! String,
                voted: array[2] as! Int == 1 ? true : false,
                totalVotes: array[1] as! Int,
                options: parsePollOption(array[3] as! [[Any]])
            ))
        } else { Optional.none }
    }
    
    private static func parsePollOption(_ array: [[Any]]) -> [Topic.Poll.Option] {
        return array.map { option in
            var choices: [Topic.Poll.Choice] = []
            
            let votes = option[3] as! [Int]
            let names = option[2] as! [String]
            
            for i in 0...(votes.count - 1) {
                choices.append(Topic.Poll.Choice(
                    id: i,
                    name: names[i],
                    votes: votes[i]
                ))
            }
            
            return Topic.Poll.Option(
                name: option[0] as! String,
                several: option[1] as! Int == 1 ? true : false,
                choices: choices
            )
        }
    }
    
    private static func parsePost(_ array: [[Any]]) -> [Post] {
        return array.map { post in
            let lastEdit: Optional<Post.LastEdit> = if post.count > 13 {
                .some(Post.LastEdit(
                    userId: post[16] as! Int,
                    username: post[14] as! String,
                    reason: post[15] as! String,
                    date: Date(timeIntervalSince1970: post[13] as! TimeInterval)
                ))
            } else { .none }
            
            return Post(
                id: post[0] as! Int,
                first: post[1] as! Int == 1 ? true : false,
                flag: post[4] as! Int,
                content: post[8] as! String,
                author: Post.Author(
                    id: post[2] as! Int,
                    name: post[3] as! String,
                    avatarUrl: post[9] as! String,
                    lastSeenDate: Date(timeIntervalSince1970: post[5] as! TimeInterval),
                    signature: post[10] as! String,
                    reputationCount: post[6] as! Int
                ),
                karma: (post[12] as! Int) >> 3,
                attachments: parseAttachment(post[11] as! [[Any]]),
                createdAt: Date(timeIntervalSince1970: post[7] as! TimeInterval),
                lastEdit: lastEdit
            )
        }
    }
    
    private static func parseAttachment(_ array: [[Any]]) -> [Post.Attachment] {
        return array.map { attachment in
            let metadata: Optional<Post.Attachment.Metadata> = if attachment.count > 4 {
                .some(Post.Attachment.Metadata(
                    width: attachment[5] as! Int,
                    height: attachment[6] as! Int,
                    url: attachment[4] as! String
                ))
            } else { .none }
            
            let type = if attachment[1] as! Int == 1 {
                Post.Attachment.AttachmentType.image
            } else {
                Post.Attachment.AttachmentType.file
            }
            
            return Post.Attachment(
                id: attachment[0] as! Int,
                type: type,
                name: attachment[2] as! String,
                size: attachment[3] as! Int,
                metadata: metadata
            )
        }
    }
}
