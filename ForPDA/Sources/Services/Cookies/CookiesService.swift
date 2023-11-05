//
//  CookiesService.swift
//  ForPDA
//
//  Created by Subvert on 21.05.2023.
//

import WebKit
import Factory

final class CookiesService {
    
    @Injected(\.settingsService) private var settingsService
    
    /// Stores saved cookies from UserDefaults to HTTPCookieStorage
    func configureCookies() {
        // We need 3 cookies to authorize: anonymous, member_id, pass_hash
        // There's also __fixmid cookie, but it lasts for a second and then removed
        if let cookies = HTTPCookieStorage.shared.cookies, cookies.count < 3 {
            // Getting saved cookies if present
            if let cookiesData = settingsService.getCookiesAsData() {
                // Decoding custom Cookie class since HTTPCookie doesn't support Codable
                if let cookies = try? JSONDecoder().decode([Cookie].self, from: cookiesData) {
                    // Force-casting Cookie to HTTPCookie and setting them to 4pda.to domain
                    let mappedCookies = cookies.map { $0.httpCookie! }
                    storeCookies(mappedCookies, forURL: URL.fourpda)
                    // !!! Must sync cookies after that (e.g. SceneDelegate since it's not working in AppDelegate) !!!
                } else {
                    // Deleting all cookies in defaults if we can't decode them and logout
                    settingsService.logout()
                }
            } else {
                // Deleting all cookies in case we don't have them saved to prevent different sources of truth and logout
                settingsService.logout()
            }
        }
    }
    
    /// Gets cookies from HTTPCookieStorage
    func getCookies(forURL url: URL) -> [HTTPCookie] {
        return HTTPCookieStorage.shared.cookies(for: url) ?? []
    }
    
    /// Deletes cookies from HTTPCookieStorage
    func deleteCookies(forURL url: URL) {
        for cookie in getCookies(forURL: url) {
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
    }
    
    /// Stores cookies to HTTPCookieStorage
    func storeCookies(_ cookies: [HTTPCookie], forURL url: URL) {
        HTTPCookieStorage.shared.setCookies(cookies, for: url, mainDocumentURL: nil)
    }
    
    /// Syncs cookies between URLSession & WKWebView (so FLS/SLS works in sync)
    func syncCookies() {
        for cookie in HTTPCookieStorage.shared.cookies ?? [] {
            WKWebsiteDataStore.default().httpCookieStore.setCookie(cookie)
        }
    }
}
