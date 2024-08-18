//
//  ProfileParser.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 02.08.2024.
//

import Foundation
import Models

public struct ProfileParser {
    
    /// 0. 69383 - request id
    /// 1. 0 - response status ok
    /// 2. 3640948 - user id
    /// 3. 4spader - nickname
    /// 4. https://4pda.to/static/forum/uploads/48/3640948-28843594.jpg - image url
    /// 5. 3 - group id (beginning)
    /// 6. "" - status
    /// 7. "" - signature
    /// 8. "" - text about me
    /// 9. 1379589700 - registration date
    /// 10. 1722630734 - last seen date (0 if hidden)
    /// 11. "" - date of birth
    /// 12. 0 - gender (0/1/2, unknown/male/female)
    /// 13. 10800 - user time
    /// 14. "Нет" - user city
    /// 15. [] - devices on devdb
    /// 16. 800 - karma amount
    /// 17. 0 - posts amount
    /// 18. 5 - comments amount
    /// 19. 1 - reputation amount
    /// 20. 0 - topics amount
    /// 21. 10 - replies amount
    /// 22. 0 - qms messages
    /// 23. [] - devices on forum
    /// 24. [] - warning log
    /// 25. something@gmail.com - email
    /// 26. "" - empty = no warnings
    /// 27. "" - empty = no warnings
    /// 28. -1 - warning level (-1 => 0%)
    /// 29. 0 - user premod (1 - always | 0 - before ...)
    /// 30. 0 - user readonly (if != 0 => before ...)
    /// 31. 0 - ban reason (1 - last chanse | 2 - permanent | 3 - security block)
    /// 32. [] - rewards list
    /// 33. "" - ???
    
    public static func parseUser(rawString string: String) throws -> User {
        if let data = string.data(using: .utf8) {
            do {
                guard let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] else { throw ParsingError.failedToCastDataToAny }
                return User(
                    id: array[2] as! Int,
                    nickname: array[3] as! String,
                    imageUrl: URL(string: array[4] as! String),
                    registrationDate: Date(timeIntervalSince1970: array[9] as! TimeInterval),
                    lastSeenDate: Date(timeIntervalSince1970: array[10] as! TimeInterval),
                    userCity: array[14] as! String,
                    karma: array[16] as! Int,
                    posts: array[17] as! Int,
                    comments: array[18] as! Int,
                    reputation: array[19] as! Int,
                    topics: array[20] as! Int,
                    replies: array[21] as! Int,
                    email: array[25] as! String
                )
            } catch {
                throw ParsingError.failedToSerializeData(error)
            }
        } else {
            throw ParsingError.failedToCreateDataFromString
        }
    }
}
