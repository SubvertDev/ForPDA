//
//  FormValue.swift
//  ForPDA
//
//  Created by Xialtal on 22.02.26.
//

import APIClient

public enum FormValue: Sendable, Hashable {
    case string(String)
    case integer(Int)
    
    case array([FormValue])
}

extension FormValue {
    static func toDocument(_ values: [FormValue]) throws -> PDAPIDocument {
        let document = PDAPIDocument()
        for value in values {
            try document.append(value)
        }
        return document
    }
    
    static func getIntArray(_ values: [FormValue]) -> [Int] {
        var array: [Int] = []
        for value in values {
            if case let .integer(int) = value {
                array.append(int)
            }
        }
        return array
    }
}

private extension PDAPIDocument {
    func append(_ value: FormValue) throws {
        switch value {
        case .string(let string):
            _ = try append(string)

        case .integer(let int):
            _ = try append(int)

        case .array(let array):
            let nestedDocument = PDAPIDocument()
            for element in array {
                try nestedDocument.append(element)
            }
            _ = try append(nestedDocument)
        }
    }
}
