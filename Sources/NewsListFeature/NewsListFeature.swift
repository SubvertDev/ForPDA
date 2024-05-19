//
//  NewsListFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import Foundation
import ComposableArchitecture
import Models
import NewsClient
import AnalyticsClient
import PasteboardClient

@Reducer
public struct NewsListFeature {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var alert: AlertState<Action.Alert>?
        public var news: [NewsPreview]
        public var isLoading: Bool
        public var showShareSheet: Bool
        public var showVpnWarningBackground: Bool
        
        public init(
            alert: AlertState<Action.Alert>? = nil,
            news: [NewsPreview] = [],
            isLoading: Bool = true,
            showShareSheet: Bool = false,
            showVpnWarningBackground: Bool = false
        ) {
            self.alert = alert
            self.news = news
            self.isLoading = isLoading
            self.showShareSheet = showShareSheet
            self.showVpnWarningBackground = showVpnWarningBackground
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction {
        case menuTapped
        case newsTapped(NewsPreview)
        case cellMenuOpened(NewsPreview, NewsListRowMenuAction) // RELEASE: Half-delegate?
        case onTask
        case onRefresh
        case binding(BindingAction<State>)
        
        case _newsResponse(Result<[NewsPreview], Error>)
        
        case alert(PresentationAction<Alert>)
        public enum Alert {
            case openCaptcha
            case cancel
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.newsClient) var newsClient
    @Dependency(\.pasteboardClient) var pasteboardClient
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .menuTapped:
//                analyticsClient.log(.newsList(.menuTapped))
                return .none
            
            case .newsTapped:
//                analyticsClient.log(.newsList(.newsTapped(news.url)))
                return .none
                
            case .binding:
                return .none
                
            case .cellMenuOpened(let news, let action):
                switch action {
                case .copyLink:
                    pasteboardClient.copy(url: news.url)
                    
                case .shareLink:
                    state.showShareSheet = true
                    
                case .report:
                    break
                }
                return .none
                
            case .onTask:
                return .run { send in
                    let result = await Result { try await newsClient.newsList(page: 1) }
                    await send(._newsResponse(result))
                }
                
            case .onRefresh:
                return .run { send in
                    let startTime = DispatchTime.now()
                    let result = await Result { try await newsClient.newsList(page: 1) }
                    let endTime = DispatchTime.now()
                    let timeInterval = Int(Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds))
                    try await Task.sleep(for: .nanoseconds(1_000_000_000 - timeInterval))
                    await send(._newsResponse(result))
                }
                
            case let ._newsResponse(.success(news)):
                state.isLoading = false
                state.news = news
                return .none
                
            case ._newsResponse(.failure):
                state.isLoading = false
                state.alert = .vpnWarning // RELEASE: Triggers if no internet
                return .none
                
            case .alert(.presented(.openCaptcha)):
                return .none
                
            case .alert(.presented(.cancel)):
                return .none
                
            case .alert:
                state.alert = nil
                state.showVpnWarningBackground = true
                return .none
            }
        }
        
        Analytics()
    }
}

// MARK: - Alert Extension

extension AlertState where Action == NewsListFeature.Action.Alert {
    static let vpnWarning = Self {
        TextState("Упс!")
    } actions: {
        ButtonState(action: .openCaptcha) {
            TextState("Показать капчу")
        }
        ButtonState(role: .cancel, action: .cancel) {
            TextState("OK")
        }
    } message: {
        TextState("Похоже у вас запущен ВПН или вы находитесь не в России, на данный момент обход капчи находится в тестовом режиме и может работать некорректно, рекомендуется отключить ВПН вместо ввода капчи")
    }
}
