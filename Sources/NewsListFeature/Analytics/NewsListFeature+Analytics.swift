//
//  NewsListFeature+Analytics.swift
//
//
//  Created by Ilia Lubianoi on 19.05.2024.
//

import Foundation
import ComposableArchitecture
import AnalyticsClient

extension NewsListFeature {
    struct Analytics: Reducer {
        typealias State = NewsListFeature.State
        typealias Action = NewsListFeature.Action
        
        @Dependency(\.analyticsClient) var analyticsClient
        
        var body: some ReducerOf<Self> {
            Reduce { state, action in
                switch action {
                case .menuTapped:
                    analyticsClient.log(NewsListEvent.menuTapped)
                    
                case .newsTapped(let news):
                    analyticsClient.log(NewsListEvent.newsTapped(news.url))
                    
                case .cellMenuOpened(let news, let action):
                    switch action {
                    case .copyLink:
                        analyticsClient.log(NewsListEvent.linkCopied(news.url))
                    case .shareLink:
                        analyticsClient.log(NewsListEvent.linkShared(news.url))
                    case .report:
                        analyticsClient.log(NewsListEvent.linkReported(news.url))
                        analyticsClient.capture(AnalyticsError.brokenNews(news.url))
                    }
                    
                case .onTask:
                    break // RELEASE: Make First App Open/App Session here?
                    
                case .onRefresh:
                    analyticsClient.log(NewsListEvent.refreshTriggered)
                    
                case ._newsResponse(.failure):
                    analyticsClient.log(NewsListEvent.vpnWarningShown)
                    
                case .alert(.presented(.openCaptcha)):
                    analyticsClient.log(NewsListEvent.vpnWarningAction(.openCaptcha))
                    
                case .alert(.presented(.cancel)):
                    analyticsClient.log(NewsListEvent.vpnWarningAction(.cancel))
                    
                case .binding, .alert, ._newsResponse(.success):
                    break
                }
                return .none
            }
        }
    }
}
