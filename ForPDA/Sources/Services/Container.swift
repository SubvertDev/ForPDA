//
//  Container.swift
//  ForPDA
//
//  Created by Subvert on 08.05.2023.
//

import Foundation
import Factory

extension Container {
    
    // MARK: Network
    
    var newsService: Factory<NewsServicable> {
        Factory(self) { NewsService() }
            .singleton
    }
    
    var authService: Factory<AuthServicable> {
        Factory(self) { AuthService() }
            .singleton
    }
    
    var userService: Factory<UserServicable> {
        Factory(self) { UserService() }
            .singleton
    }
    
    // MARK: Common
    
    var parsingService: Factory<ParsingService> {
        Factory(self) { ParsingService() }
    }
    
    var settingsService: Factory<SettingsService> {
        Factory(self) { SettingsService() }
    }
    
    var analyticsService: Factory<AnalyticsService> {
        Factory(self) { AnalyticsService() }
    }
    
    var cookiesService: Factory<CookiesService> {
        Factory(self) { CookiesService() }
    }
}
