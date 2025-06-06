//
//  TopicParser.swift
//  ForPDA
//
//  Created by Xialtal on 7.09.24.
//

import Foundation
import Models

public struct TopicParser {
    
    // MARK: - Topic
    
    public static func parse(from string: String) throws(ParsingError) -> Topic {
        guard let data = string.data(using: .utf8) else {
            throw ParsingError.failedToCreateDataFromString
        }
        
        guard let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] else {
            throw ParsingError.failedToCastDataToAny
        }
        
        guard let navigation = array[safe: 2] as? [[Any]],
              let id = array[safe: 3] as? Int,
              let name = array[safe: 4] as? String,
              let description = array[safe: 5] as? String,
              let flag = array[safe: 6] as? Int,
              let createdAt = array[safe: 7] as? TimeInterval,
              let authorId = array[safe: 8] as? Int,
              let authorName = array[safe: 9] as? String,
              let curatorId = array[safe: 10] as? Int,
              let curatorName = array[safe: 11] as? String,
              let poll = array[safe: 12] as? [Any],
              let postsCount = array[safe: 13] as? Int,
              let posts = array[safe: 14] as? [[Any]],
              let postTemplates = array[safe: 15] as? [String] else {
            throw ParsingError.failedToCastFields
        }
        
        return Topic(
            id: id,
            name: name.convertCodes(),
            description: description.convertCodes(),
            flag: flag,
            createdAt: Date(timeIntervalSince1970: createdAt),
            authorId: authorId,
            authorName: authorName.convertCodes(),
            curatorId: curatorId,
            curatorName: curatorName,
            poll: try parsePoll(poll),
            postsCount: postsCount,
            posts: try parsePosts(posts),
            navigation: ForumParser.parseNavigation(navigation),
            postTemplateName: !postTemplates.isEmpty ? postTemplates[safe: 0] : nil
        )
    }
    
    public static func parsePostPreview(from string: String) throws(ParsingError) -> PostPreview {
        guard let data = string.data(using: .utf8) else {
            throw ParsingError.failedToCreateDataFromString
        }
        
        guard let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] else {
            throw ParsingError.failedToCastDataToAny
        }
        
        guard let content = array[safe: 2] as? String,
              let attachmentIds = array[safe: 3] as? [Int] else {
            throw ParsingError.failedToCastFields
        }
        
        return PostPreview(content: content, attachmentIds: attachmentIds)
    }
    
    public static func parsePostSend(from string: String) throws(ParsingError) -> PostSend {
        guard let data = string.data(using: .utf8) else {
            throw ParsingError.failedToCreateDataFromString
        }
        
        guard let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] else {
            throw ParsingError.failedToCastDataToAny
        }
        
        guard let id = array[safe: 4] as? Int,
              let topicId = array[safe: 2] as? Int,
              let offset = array[safe: 3] as? Int else {
            throw ParsingError.failedToCastFields
        }
        
        return PostSend(id: id, topicId: topicId, offset: offset)
    }
    
    // MARK: - Poll
    
    private static func parsePoll(_ array: [Any]) throws(ParsingError) -> Topic.Poll? {
        if array.isEmpty {
            return nil
        }
        
        guard let name = array[safe: 0] as? String,
              let totalVotes = array[safe: 1] as? Int,
              let voted = array[safe: 2] as? Int,
              let options = array[safe: 3] as? [[Any]] else {
            throw ParsingError.failedToCastFields
        }
        
        return if !array.isEmpty {
            Topic.Poll(
                name: name,
                voted: voted == 1 ? true : false,
                totalVotes: totalVotes,
                options: try parsePollOptions(options)
            )
        } else { nil }
    }
    
    // MARK: - Poll Options
    
    private static func parsePollOptions(_ optionsRaw: [[Any]]) throws(ParsingError) -> [Topic.Poll.Option] {
        var options: [Topic.Poll.Option] = []
        for option in optionsRaw {
            guard let name = option[safe: 0] as? String,
                  let several = option[safe: 1] as? Int,
                  let names = option[safe: 2] as? [String],
                  let votes = option[safe: 3] as? [Int] else {
                throw ParsingError.failedToCastFields
            }
            
            var choices: [Topic.Poll.Choice] = []
            
            for index in votes.indices {
                let choice = Topic.Poll.Choice(
                    id: index,
                    name: names[index],
                    votes: votes[index]
                )
                choices.append(choice)
            }
            
            let option = Topic.Poll.Option(
                name: name,
                several: several == 1 ? true : false,
                choices: choices
            )
            options.append(option)
        }
        return options
    }
    
    // MARK: - Posts
    
    private static func parsePosts(_ postsRaw: [[Any]]) throws(ParsingError) -> [Post] {
        var posts: [Post] = []
        for post in postsRaw {
            guard let id = post[safe: 0] as? Int,
                  let flag = post[safe: 1] as? Int,
                  let authorId = post[safe: 2] as? Int,
                  let authorName = post[safe: 3] as? String,
                  let authorGroupId = post[safe: 4] as? Int,
                  let authorLastSeenDate = post[safe: 5] as? TimeInterval,
                  let authorReputationCount = post[safe: 6] as? Int,
                  let createdAt = post[safe: 7] as? TimeInterval,
                  let content = post[safe: 8] as? String,
                  let authorAvatarUrl = post[safe: 9] as? String,
                  let authorSignature = post[safe: 10] as? String,
                  let attachments = post[safe: 11] as? [[Any]],
                  let karma = post[safe: 12] as? Int else {
                throw ParsingError.failedToCastFields
            }
            
            let post = Post(
                id: id,
                flag: flag,
                content: content,
                author: Post.Author(
                    id: authorId,
                    name: authorName.convertCodes(),
                    groupId: authorGroupId,
                    avatarUrl: authorAvatarUrl,
                    lastSeenDate: Date(timeIntervalSince1970: authorLastSeenDate),
                    signature: authorSignature,
                    reputationCount: authorReputationCount
                ),
                karma: karma >> 3,
                attachments: try parseAttachment(attachments),
                createdAt: Date(timeIntervalSince1970: createdAt),
                lastEdit: try parseLastEdit(post)
            )
            posts.append(post)
        }
        return posts
    }
    
    // MARK: - Attachment
    
    private static func parseAttachment(_ attachmentsRaw: [[Any]]) throws(ParsingError) -> [Post.Attachment] {
        var attachments: [Post.Attachment] = []
        for attachment in attachmentsRaw {
            guard let id = attachment[safe: 0] as? Int,
                  let type = attachment[safe: 1] as? Int,
                  let name = attachment[safe: 2] as? String,
                  let size = attachment[safe: 3] as? Int else {
                throw ParsingError.failedToCastFields
            }
            
            guard let type = Post.Attachment.AttachmentType(rawValue: type) else {
                throw ParsingError.unknownAttachmentType(type)
            }
            
            let downloadCount = (attachment[safe: 7] as? Int) ?? (attachment[safe: 4] as? Int)
            
            let attachment = Post.Attachment(
                id: id,
                type: type,
                name: name,
                size: size,
                metadata: try parseAttachmentMetadata(attachment),
                downloadCount: downloadCount // Only if attachment.count > 7
            )
            attachments.append(attachment)
        }
        return attachments
    }
    
    // MARK: - Attachment Metadata
     
    private static func parseAttachmentMetadata(_ attachment: [Any]) throws(ParsingError) -> Post.Attachment.Metadata? {
        if attachment.count <= 5 {
            return nil
        }
        
        guard let url = attachment[safe: 4] as? String,
              let width = attachment[safe: 5] as? Int,
              let height = attachment[safe: 6] as? Int else {
            throw ParsingError.failedToCastFields
        }
        
        guard let url = URL(string: url) else {
            throw ParsingError.failedToCreateAttachmentMetadataUrl
        }
        
        return Post.Attachment.Metadata(
            width: width,
            height: height,
            url: url
        )
    }
    
    // MARK: - Last Edit
    
    private static func parseLastEdit(_ post: [Any]) throws(ParsingError) -> Post.LastEdit? {
        if post.count <= 13 {
            return nil
        }
        
        guard let date = post[safe: 13] as? TimeInterval,
              let username = post[safe: 14] as? String,
              let reason = post[safe: 15] as? String,
              let userId = post[safe: 16] as? Int else {
            throw ParsingError.failedToCastFields
        }
       
        return Post.LastEdit(
            userId: userId,
            username: username.convertCodes(),
            reason: reason,
            date: Date(timeIntervalSince1970: date)
        )
    }
}
