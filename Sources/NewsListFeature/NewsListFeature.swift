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

@Reducer
public struct NewsListFeature {
    
    // MARK: - State
    
    @ObservableState
    public struct State {
        @Presents public var alert: AlertState<Action.Alert>?
        public var news: [News] = []
        public var isLoading = true
        public var showVpnWarningBackground = false
        
        public init() {}
    }
    
    // MARK: - Action
    
    public enum Action {
        case menuTapped
        case newsTapped(News.ID)
        case onTask
        case onRefresh
        
        case newsResponse(Result<[News], Error>)
        
        case alert(PresentationAction<Alert>)
        public enum Alert {
            case openCaptcha
        }
    }
    
    // MARK: - Init
    
    public init() {}
    
    // MARK: - Dependencies
    
    @Dependency(\.newsClient) var newsClient
//    @Dependency(\.analyticsClient) var analyticsClient
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .menuTapped:
                return .none
            
            case .newsTapped:
                return .none
                
            case .onTask:
                return .run { send in
                    let result = await Result { try await newsClient.newsList(page: 1) }
                    await send(.newsResponse(result))
                }
                
            case .onRefresh:
                return .run { send in
                    let startTime = DispatchTime.now()
                    let result = await Result { try await newsClient.newsList(page: 1) }
                    let endTime = DispatchTime.now()
                    let timeInterval = Int(Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds))
                    try await Task.sleep(for: .nanoseconds(1_000_000_000 - timeInterval))
                    await send(.newsResponse(result))
                }
                
            case let .newsResponse(.success(news)):
                state.isLoading = false
                state.news = news
                return .none
                
            case .newsResponse(.failure):
                state.isLoading = false
                state.alert = .vpnWarning
                return .none
                
            case .alert(.presented(.openCaptcha)):
                return .none
                
            case .alert:
                state.alert = nil
                state.showVpnWarningBackground = true
                return .none
            }
        }
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
        ButtonState(role: .cancel) {
            TextState("OK")
        }
    } message: {
        TextState("Похоже у вас запущен ВПН или вы находитесь не в России, на данный момент обход капчи находится в тестовом режиме и может работать некорректно, рекомендуется отключить ВПН вместо ввода капчи")
    }
}
