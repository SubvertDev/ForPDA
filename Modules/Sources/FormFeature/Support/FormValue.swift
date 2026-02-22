//
//  FormValue.swift
//  ForPDA
//
//  Created by Xialtal on 22.02.26.
//

import PDAPI

public enum FormValue: Hashable {
    case string(String)
    case integer(Int)
    
    case array([FormValue])
    
    static func toDocument(_ value: FormValue) throws -> Document {
        var document = Document()
        switch value {
        case .string(let string):
            _ = try document.append(string)
        case .integer(let int):
            _ = try document.append(int)
        case .array(let array):
            for element in array {
                _ = try document.append(toDocument(element))
            }
        }
        return document
    }
}
