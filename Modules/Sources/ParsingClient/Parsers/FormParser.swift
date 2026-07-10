//
//  FormParser.swift
//  ForPDA
//
//  Created by Xialtal on 14.03.25.
//

import Foundation
import Models

public struct FormParser {

    public static func parse(from string: String) throws(ParsingError) -> [FormFieldType] {
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
    
    public static func parseTemplatePreview(from string: String) throws(ParsingError) -> PreviewResponse {
        guard let data = string.data(using: .utf8) else {
            throw ParsingError.failedToCreateDataFromString
        }
        
        guard let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] else {
            throw ParsingError.failedToCastDataToAny
        }
        
        guard let template = array[safe: 2] as? [Any],
              let content = template[safe: 2] as? String,
              let attachmentsRaw = template[safe: 3] as? [[Any]],
              let attachments = try? AttachmentParser.parseAttachment(attachmentsRaw) else {
            throw ParsingError.failedToCastFields
        }
        
        return PreviewResponse(content: content, attachments: attachments)
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
            if array.count > 3 {
                let response = try TopicParser.parsePostSendResponse(from: string)
                switch response {
                case let .success(post):
                    return .success(.post(post))
                case let .failure(error):
                    throw .unknownStatus(error.rawValue)
                }
            } else {
                return .success(.topic(id: array[safe: 2] as! Int))
            }
            
        case 5:
            guard let errors = array[safe: 2] as? [Any] else {
                throw ParsingError.failedToCastFields
            }
            return .failure(.fieldsError(errors.description))
            
        case 3:
            return .failure(.badParam)
            
        case 4:
            return .failure(.sentToPremod)
            
        default:
            return .failure(.status(status))
        }
    }
    
    private static func parseFormFields(_ fieldsRaw: [[Any]]) throws(ParsingError)-> [FormFieldType] {
        var formFields: [FormFieldType] = []
        for (index, field) in fieldsRaw.enumerated() {
            guard let type = field[safe: 0] as? String,
                  let name = field[safe: 1] as? String,
                  let description = field[safe: 2] as? String,
                  let example = field[safe: 3] as? String,
                  let flag = field[safe: 4] as? Int,
                  let defaultValue = field[safe: 5] as? String else {
                throw ParsingError.failedToCastFields
            }
            
            let content = FormFieldType.FormField(
                id: index,
                name: name,
                description: description,
                example: example,
                flag: FormFieldFlag(rawValue: flag),
                defaultValue: defaultValue
            )
            
            switch type {
            case "text", "editor":
                let maxLenght: Int? = field[safe: 7] as? Int
                formFields.append(
                    type == "text"
                    ? .text(content, maxLenght: maxLenght == 0 ? nil : maxLenght)
                    : .editor(content)
                )
                
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
