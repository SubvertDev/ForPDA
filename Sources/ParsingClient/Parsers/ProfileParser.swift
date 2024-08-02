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
    /// 1. 0 - ???
    /// 2. 3640948 - user id
    /// 3. 4spader - nickname
    /// 4. https://4pda.to/static/forum/uploads/48/3640948-28843594.jpg - image url
    /// 5. 3 - ???
    /// 6. "" - ???
    /// 7. "" - ???
    /// 8. "" - ???
    /// 9. 1379589700 - registration date
    /// 10. 1722630734 - lastSeen ???
    /// 11. "" - ???
    /// 12. 0 - ???
    /// 13. 10800 - ???
    /// 14. "Нет" - user city
    /// 15. [] - ???
    /// 16. 800 - karma amount
    /// 17. 0 - posts amount
    /// 18. 5 - comments amount
    /// 19. 1 - reputation amount
    /// 20. 0 - topics amount
    /// 21. 10 - replies amount
    /// 22. 0 - ???
    /// 23. [] - ???
    /// 24. [] - ???
    /// 25. something@gmail.com - email
    /// 26. "" - ???
    /// 27. "" - ???
    /// 28. -1 - ???
    /// 29. 0 - ???
    /// 30. 0 - ???
    /// 31. 0 - ???
    /// 32. [] - ???
    /// 33. "" - ???
    
    public static func parseUser(rawString string: String) throws -> User {
        if let data = string.data(using: .utf8) {
            do {
                guard let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] else { throw ParsingError.failedToCastDataToAny }
                return User(
                    id: array[2] as! Int,
                    nickname: array[3] as! String,
                    imageUrl: URL(string: array[4] as! String)!,
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
