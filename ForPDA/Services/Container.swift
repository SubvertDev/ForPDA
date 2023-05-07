//
//  Container.swift
//  ForPDA
//
//  Created by Subvert on 08.05.2023.
//

import Foundation
import Factory

extension Container {
    var networkService: Factory<NetworkManager> {
        Factory(self) { NetworkManager() }
            .singleton
    }
    
    var parsingService: Factory<ParsingService> {
        Factory(self) { ParsingService() }
            .singleton
    }
    
    var analyticsService: Factory<AnalyticsService> {
        Factory(self) { AnalyticsService() }
            .singleton
    }
}
