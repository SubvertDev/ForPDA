//
//  CookiesClient.swift
//
//
//  Created by Ilia Lubianoi on 18.05.2024.
//

import Foundation
import ComposableArchitecture
import WebKit
import SettingsClient
import Models

@DependencyClient
public struct CookiesClient {
    /// Stores saved cookies from UserDefaults to HTTPCookieStorage
    public var configure: () -> Void
    /// Gets cookies from HTTPCoolieStorage
    public var get: (_ url: URL) -> [HTTPCookie] = { _ in [] }
    /// Deletes cookies from HTTPCookieStorage
    public var delete: (_ url: URL) -> Void
    /// Stores cookies into HTTPCookieStorage
    public var store: (_ cookies: [HTTPCookie], _ url: URL) -> Void
    /// Syncs cookies between URLSession & WKWebView (so FLS/SLS works in sync)
    public var sync: () -> Void
}

public extension DependencyValues {
    var cookiesClient: CookiesClient {
        get { self[CookiesClient.self] }
        set { self[CookiesClient.self] = newValue }
    }
}

extension CookiesClient: DependencyKey {
    public static let liveValue = Self(
        configure: {
            // RELEASE: Is it a right way?
            @Dependency(\.cookiesClient) var cookiesClient
            @Dependency(\.settingsClient) var settingsClient
            // We need 3 cookies to authorize: anonymous, member_id, pass_hash
            // There's also __fixmid cookie, but it lasts for a second and then removed
            if let cookies = HTTPCookieStorage.shared.cookies, cookies.count < 3 {
                // Getting saved cookies if present
                if let cookiesData = settingsClient.getCookiesData() {
                    // Decoding custom Cookie class since HTTPCookie doesn't support Codable
                    if let cookies = try? JSONDecoder().decode([Cookie].self, from: cookiesData) {
                        // Force-casting Cookie to HTTPCookie and setting them to 4pda.to domain
                        let mappedCookies = cookies.map { $0.httpCookie! }
                        cookiesClient.store(cookies: mappedCookies, url: URL.fourpda)
                        // !!! Must sync cookies after that (e.g. SceneDelegate since it's not working in AppDelegate) !!!
                    } else {
                        // Deleting all cookies in defaults if we can't decode them and logout
                        settingsClient.logout()
                    }
                } else {
                    // Deleting all cookies in case we don't have them saved to prevent different sources of truth and logout
                    settingsClient.logout()
                }
            }
        }, 
        get: { url in
            return HTTPCookieStorage.shared.cookies(for: url) ?? []
        }, 
        delete: { url in
            // RELEASE: Check if it's working
            @Dependency(\.cookiesClient) var client
            for cookie in client.get(url: url) {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        },
        store: { cookies, url in
            HTTPCookieStorage.shared.setCookies(cookies, for: url, mainDocumentURL: nil)
        }, 
        sync: {
            for cookie in HTTPCookieStorage.shared.cookies ?? [] {
                WKWebsiteDataStore.default().httpCookieStore.setCookie(cookie)
            }
        }
    )
}
