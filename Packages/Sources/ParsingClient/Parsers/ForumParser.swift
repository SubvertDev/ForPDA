//
//  ForumParser.swift
//  ForPDA
//
//  Created by Xialtal on 7.09.24.
//

import Foundation
import Models

public struct ForumParser {
    public static func parse(from string: String) throws -> Forum {
        if let data = string.data(using: .utf8) {
            do {
                guard let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] else { throw ParsingError.failedToCastDataToAny }
                return Forum(
                    id: array[3] as! Int,
                    name: array[4] as! String,
                    flag: array[5] as! Int,
                    description: array[6] as! String,
                    announcements: parseAnnouncementInfo(array[7] as! [[Any]]),
                    subforums: parseForumInfo(array[8] as! [[Any]]),
                    topicsCount: array[9] as! Int,
                    topics: parseTopic(array[10] as! [[Any]]),
                    navigation: parseNavigation(array[2] as! [[Any]])
                )
            } catch {
                throw ParsingError.failedToSerializeData(error)
            }
        } else {
            throw ParsingError.failedToCreateDataFromString
        }
    }
    
    public static func parseForumList(from string: String) throws -> [ForumInfo] {
        if let data = string.data(using: .utf8) {
            do {
                guard let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] else { throw ParsingError.failedToCastDataToAny }
                
                return parseForumInfo(array[2] as! [[Any]])
            } catch {
                throw ParsingError.failedToSerializeData(error)
            }
        } else {
            throw ParsingError.failedToCreateDataFromString
        }
    }
    
    public static func parseForumJump(from string: String) throws -> ForumJump {
        if let data = string.data(using: .utf8) {
            do {
                guard let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] else { throw ParsingError.failedToCastDataToAny }
                
                return ForumJump(
                    id: array[2] as! Int,
                    offset: array[3] as! Int,
                    postId: array[4] as! Int,
                    allPosts: array[5] as! Int == 1 ? true : false
                )
            } catch {
                throw ParsingError.failedToSerializeData(error)
            }
        } else {
            throw ParsingError.failedToCreateDataFromString
        }
    }
    
    public static func parseAnnouncement(from string: String) throws -> Announcement {
        if let data = string.data(using: .utf8) {
            do {
                guard let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] else { throw ParsingError.failedToCastDataToAny }
                
                return Announcement(
                    name: array[2] as! String,
                    content: array[3] as! String
                )
            } catch {
                throw ParsingError.failedToSerializeData(error)
            }
        } else {
            throw ParsingError.failedToCreateDataFromString
        }
    }
    
    internal static func parseNavigation(_ array: [[Any]]) -> [ForumInfo] {
        return array.map { navigation in
            return ForumInfo(
                id: navigation[1] as! Int,
                name: navigation[2] as! String,
                flag: navigation[0] as! Int
            )
        }
    }
    
    private static func parseAnnouncementInfo(_ array: [[Any]]) -> [AnnouncementInfo] {
        return array.map { announcement in
            return AnnouncementInfo(
                id: announcement[0] as! Int,
                name: announcement[1] as! String
            )
        }
    }
    
    private static func parseForumInfo(_ array: [[Any]]) -> [ForumInfo] {
        return array.map { forum in
            let redirectUrl = forum.count > 3 ? URL(string: forum[3] as! String) : nil
            
            return ForumInfo(
                id: forum[0] as! Int,
                name: (forum[1] as! String).convertCodes(),
                flag: forum[2] as! Int,
                redirectUrl: redirectUrl
            )
        }
    }
    
    private static func parseTopic(_ array: [[Any]]) -> [TopicInfo] {
        return array.map { topic in
            return parseTopic(topic)
        }
    }
        
    internal static func parseTopic(_ topic: [Any]) -> TopicInfo {
        return TopicInfo(
            id: topic[0] as! Int,
            name: (topic[1] as! String).convertCodes(),
            description: (topic[2] as! String).convertCodes(),
            flag: topic[3] as! Int,
            postsCount: topic[4] as! Int,
            lastPost: TopicInfo.LastPost(
                date: Date(timeIntervalSince1970: topic[5] as! TimeInterval),
                userId: topic[6] as! Int,
                username: (topic[7] as! String).convertCodes()
            )
        )
    }
}
