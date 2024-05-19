//
//  File.swift
//  
//
//  Created by Ilia Lubianoi on 18.05.2024.
//

import Foundation

public struct Cookie: Codable {
    var name: String
    var value: String
    var domain: String
    var path: String
    var expires: Date?
    var secure: Bool

    public init(
        _ cookie: HTTPCookie
    ) {
        name = cookie.name
        value = cookie.value
        domain = cookie.domain
        path = cookie.path
        expires = cookie.expiresDate
        secure = cookie.isSecure
    }

    public static func decode(_ data: Data) -> Cookie? {
        return try? JSONDecoder().decode(Cookie.self, from: data)
    }

    public var data: Data? {
        return try? JSONEncoder().encode(self)
    }

    public var httpCookie: HTTPCookie? {
        return HTTPCookie(properties: [
            HTTPCookiePropertyKey.name: name,
            HTTPCookiePropertyKey.value: value,
            HTTPCookiePropertyKey.domain: domain,
            HTTPCookiePropertyKey.path: path,
            HTTPCookiePropertyKey.expires: expires as Any,
            HTTPCookiePropertyKey.secure: secure
        ])
    }
}
