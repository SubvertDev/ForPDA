//
//  HistoryParser.swift
//  ForPDA
//
//  Created by Xialtal on 8.11.24.
//

import Foundation
import Models

public struct HistoryParser {
    public static func parse(from string: String) throws -> History {
        if let data = string.data(using: .utf8) {
            do {
                guard let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] else { throw ParsingError.failedToCastDataToAny }

                return History(
                    histories: parseHistories(array[3] as! [[Any]]),
                    historiesCount: array[2] as! Int
                )
            } catch {
                throw ParsingError.failedToSerializeData(error)
            }
        } else {
            throw ParsingError.failedToCreateDataFromString
        }
    }
    
    private static func parseHistories(_ array: [[Any]]) -> [HistoryInfo] {
        return array.map { history in
            return HistoryInfo(
                seenDate: Date(timeIntervalSince1970: history[8] as! TimeInterval),
                topic: ForumParser.parseTopic(history)
            )
        }
    }
}
