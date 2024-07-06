//
//  File.swift
//  
//
//  Created by Ilia Lubianoi on 01.07.2024.
//

import Foundation
import Parsing

public struct QuotedFieldParser: ParserPrinter {

    enum FieldError: Error {
        case unimplemented
        case logicError
        case malformed
    }

    enum ParsingState {
        case notStarted
        case midField
    }

    public init() {}

    public func parse(_ input: inout Substring) throws -> Substring {
        var result = Substring()
        var state = ParsingState.notStarted
        var quoteCount = 0

        while let character = input.first {
            input.removeFirst()
            switch state {
            case .notStarted:
                guard character == "\"" else { throw FieldError.malformed }
                state = .midField
                quoteCount += 1

            case .midField:
                if character == "\"" {
                    if input.isEmpty {
                        if quoteCount % 2 == 0 {
                            throw FieldError.malformed
                        } else {
                            return result //.utf8
                        }
                    } else {
                        quoteCount += 1
                        result.append(character)
                        if let first = input.first { // Временный хак, лучше не придумал
                            let secondIndex = input.index(after: input.startIndex)
                            let second = input[secondIndex]
                            if first == "," && second.isNumber {
                                return result
                            }
                        }
                    }
                } else {
                    result.append(character)
                }
            }
        }
        throw FieldError.malformed
    }

    public func print(_ output: Substring, into input: inout Substring) throws { }
}
