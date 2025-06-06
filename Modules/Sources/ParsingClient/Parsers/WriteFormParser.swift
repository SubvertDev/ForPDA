//
//  WriteFormParser.swift
//  ForPDA
//
//  Created by Xialtal on 14.03.25.
//

import Foundation
import Models

public struct WriteFormParser {

    public static func parse(from string: String) throws(ParsingError) -> [WriteFormFieldType] {
        guard let data = string.data(using: .utf8) else {
            throw ParsingError.failedToCreateDataFromString
        }
        
        guard let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] else {
            throw ParsingError.failedToCastDataToAny
        }
        
        guard let fields = array[safe: 2] as? [[Any]] else {
            throw ParsingError.failedToCastFields
        }
        
        return try parseFormFields(fields)
    }
    
    public static func parseTemplatePreview(from string: String) throws(ParsingError) -> PostPreview {
        guard let data = string.data(using: .utf8) else {
            throw ParsingError.failedToCreateDataFromString
        }
        
        guard let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] else {
            throw ParsingError.failedToCastDataToAny
        }
        
        guard let template = array[safe: 2] as? [Any],
              let content = template[safe: 2] as? String,
              let attachmentIds = template[safe: 3] as? [Int] else {
            throw ParsingError.failedToCastFields
        }
        
        return PostPreview(content: content, attachmentIds: attachmentIds)
    }
    
    public static func parseTemplateSend(from string: String) throws(ParsingError) -> TemplateSend {
        guard let data = string.data(using: .utf8) else {
            throw ParsingError.failedToCreateDataFromString
        }
        
        guard let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] else {
            throw ParsingError.failedToCastDataToAny
        }
        
        guard let status = array[safe: 1] as? Int else {
            throw ParsingError.failedToCastFields
        }

        switch status {
        case 0:
            // if elements > 3 - response for post.
            return if array.count > 3 {
                .success(.post(try TopicParser.parsePostSend(from: string)))
            } else {
                .success(.topic(id: array[safe: 2] as! Int))
            }
            
        case 5:
            guard let errors = array[safe: 2] as? [Any] else {
                throw ParsingError.failedToCastFields
            }
            return .error(.fieldsError(errors.description))
            
        case 3:
            return .error(.badParam)
            
        case 4:
            return .error(.sentToPremod)
            
        default:
            return .error(.status(status))
        }
    }
    
    private static func parseFormFields(_ fieldsRaw: [[Any]]) throws(ParsingError)-> [WriteFormFieldType] {
        var formFields: [WriteFormFieldType] = []
        for (index, field) in fieldsRaw.enumerated() {
            guard let type = field[safe: 0] as? String,
                  let name = field[safe: 1] as? String,
                  let description = field[safe: 2] as? String,
                  let example = field[safe: 3] as? String,
                  let flag = field[safe: 4] as? Int,
                  let defaultValue = field[safe: 5] as? String else {
                throw ParsingError.failedToCastFields
            }
            
            let content = WriteFormFieldType.FormField(
                id: index,
                name: name,
                description: description,
                example: example,
                flag: flag,
                defaultValue: defaultValue
            )
            
            switch type {
            case "text", "editor":
                formFields.append(type == "text" ? .text(content) : .editor(content))
                
            case "dropdown", "checkbox_list":
                guard let options = field[6] as? [String] else {
                    throw ParsingError.failedToCastFields
                }
                formFields.append(type == "dropdown" ? .dropdown(content, options) : .checkboxList(content, options))
                
            case "upload_box":
                guard let extensions = field[7] as? [String] else {
                    throw ParsingError.failedToCastFields
                }
                formFields.append(.uploadbox(content, extensions))
                
            case "title":
                formFields.append(.title(content.example))
                
            default:
                throw ParsingError.failedToCastFields
            }
        }
        return formFields
    }
}
