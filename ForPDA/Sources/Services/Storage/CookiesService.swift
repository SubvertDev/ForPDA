//
//  CookiesService.swift
//  ForPDA
//
//  Created by Subvert on 21.05.2023.
//

import Foundation

final class CookiesService {
    
    func readCookie(forURL url: URL) -> [HTTPCookie] {
        let cookieStorage = HTTPCookieStorage.shared
        let cookies = cookieStorage.cookies(for: url) ?? []
        return cookies
    }
    
    func deleteCookies(forURL url: URL) {
        let cookieStorage = HTTPCookieStorage.shared
        
        for cookie in readCookie(forURL: url) {
            cookieStorage.deleteCookie(cookie)
        }
    }
    
    func storeCookies(_ cookies: [HTTPCookie], forURL url: URL) {
        let cookieStorage = HTTPCookieStorage.shared
        cookieStorage.setCookies(cookies, for: url, mainDocumentURL: nil)
    }
}
