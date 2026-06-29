//
//  UserPunishmentParser.swift
//  ForPDA
//
//  Created by Xialtal on 27.06.26.
//

import Foundation
import Models

public struct UserPunishmentParser {
    
    // MARK: - Templates
    
    public static func parseTemplateCategories(from string: String) throws(ParsingError) -> [UserPunishmentCategory] {
        guard let data = string.data(using: .utf8) else {
            throw ParsingError.failedToCreateDataFromString
        }
        
        guard let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] else {
            throw ParsingError.failedToCastDataToAny
        }
        
        guard let contentRaw = array[safe: 5] as? [[Any]] else {
            throw ParsingError.failedToCastFields
        }
        
        return try! contentRaw.map { categoryRaw in
            guard let id = categoryRaw[safe: 0] as? String,
                  let title = categoryRaw[safe: 1] as? String,
                  let flag = categoryRaw[safe: 2] as? Int,
                  let templatesRaw = categoryRaw[safe: 3] as? [[Any]],
                  let templates = try? parseTemplates(templatesRaw) else {
                throw ParsingError.failedToCastFields
            }
            
            return UserPunishmentCategory(
                id: id,
                title: title,
                supportsRestrictions: flag & 1 != 0,
                templates: templates
            )
        }
    }
    
    private static func parseTemplates(_ templatesRaw: [[Any]]) throws(ParsingError) -> [UserPunishmentTemplate] {
        var templates: [UserPunishmentTemplate] = []
        for template in templatesRaw {
            guard let id = template[safe: 0] as? String,
                  let title = template[safe: 1] as? String,
                  let reason = template[safe: 2] as? String,
                  let message = template[safe: 3] as? String,
                  let flag = template[safe: 4] as? Int else {
                throw ParsingError.failedToCastFields
            }
            
            let premoderationHours = template[safe: 5] as? Int
            let readOnlyHours = template[safe: 6] as? Int
            
            templates.append(.init(
                id: id,
                flag: UserPunishmentTemplateFlag(rawValue: flag),
                title: title,
                reason: reason,
                message: message,
                readOnlyHours: readOnlyHours ?? 0,
                premoderationHours: premoderationHours ?? 0
            ))
        }
        return templates
    }
}
