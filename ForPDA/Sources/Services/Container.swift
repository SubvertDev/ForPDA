//
//  Container.swift
//  ForPDA
//
//  Created by Subvert on 08.05.2023.
//

import Foundation
import Factory

extension Container {
    
    var networkService: Factory<NetworkService> {
        Factory(self) { NetworkService() }
            .singleton
    }
    
    var parsingService: Factory<ParsingService> {
        Factory(self) { ParsingService() }
    }
    
    var analyticsService: Factory<AnalyticsService> {
        Factory(self) { AnalyticsService(isDebug: AppScheme.isDebug) }
    }
    
    var settingsService: Factory<SettingsService> {
        Factory(self) { SettingsService() }
    }
    
    var cookiesService: Factory<CookiesService> {
        Factory(self) { CookiesService() }
    }
}
