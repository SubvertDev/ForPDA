//
//  SearchParser.swift
//  ForPDA
//
//  Created by Рустам Ойтов on 19.08.2025.
//

import Foundation
import Models

public struct SearchParser {
    
    // MARK: - Search Response
    
    public static func parse(from string: String) throws(ParsingError) -> [SearchContent] {
        guard let data = string.data(using: .utf8) else {
            throw ParsingError.failedToCreateDataFromString
        }
        
        guard let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] else {
            throw ParsingError.failedToCastDataToAny
        }
        
        guard let content = array[safe: 3] as? [[Any]] else {
            throw ParsingError.failedToCastFields
        }
        
        return try parseSearchContent(content)
    }
    
    // MARK: - Content
    
    private static func parseSearchContent(_ contentRaw: [[Any]]) throws(ParsingError) -> [SearchContent] {
        var searchContent: [SearchContent] = []
        for content in contentRaw {
            guard let type = content[safe: 0] as? Int else {
                throw ParsingError.failedToCastFields
            }
            
            switch type {
            case 1:
                guard let topicId = content[safe: 2] as? Int,
                      let topicName = content[safe: 3] as? String else {
                    throw ParsingError.failedToCastFields
                }
                let preparedPost = Array(content.dropFirst(4))
                let post = try TopicParser.parsePost(preparedPost)
                searchContent.append(.post(.init(topicId: topicId, topicName: topicName, post: post)))
            case 2:
                let topic = ForumParser.parseTopic(Array(content.dropFirst()))
                searchContent.append(.topic(topic))
            case 4:
                let preparedArticle = Array(content.dropFirst())
                let article = try ArticlesListParser.parseArticlePreview(preparedArticle)
                searchContent.append(.article(article))
            default:
                throw ParsingError.unknownSearchContentType(type)
            }
        }
        return searchContent
    }
}
