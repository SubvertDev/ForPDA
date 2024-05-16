//
//  Cookie.swift
//  ForPDA
//
//  Created by Subvert on 22.05.2023.
//

import Foundation

struct Cookie: Codable {
    var name: String
    var value: String
    var domain: String
    var path: String
    var expires: Date?
    var secure: Bool

    init(_ cookie: HTTPCookie) {
        name = cookie.name
        value = cookie.value
        domain = cookie.domain
        path = cookie.path
        expires = cookie.expiresDate
        secure = cookie.isSecure
    }

    static func decode(_ data: Data) -> Cookie? {
        return try? JSONDecoder().decode(Cookie.self, from: data)
    }

    var data: Data? {
        return try? JSONEncoder().encode(self)
    }

    var httpCookie: HTTPCookie? {
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
