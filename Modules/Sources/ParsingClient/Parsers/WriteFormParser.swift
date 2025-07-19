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
    
    private static func parseFormFields(_ fieldsRaw: [[Any]]) throws(ParsingError)-> [WriteFormFieldType] {
        var formFields: [WriteFormFieldType] = []
        for field in fieldsRaw {
            guard let type = field[safe: 0] as? String,
                  let name = field[safe: 1] as? String,
                  let description = field[safe: 2] as? String,
                  let example = field[safe: 3] as? String,
                  let flag = field[safe: 4] as? Int,
                  let defaultValue = field[safe: 5] as? String else {
                throw ParsingError.failedToCastFields
            }
            
            let content = WriteFormFieldType.FormField(
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
