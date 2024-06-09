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
        public var news: [News]
        public var page: Int
        public var isLoading: Bool
        public var showShareSheet: Bool
        public var showVpnWarningBackground: Bool
        
        public init(
            alert: AlertState<Action.Alert>? = nil,
            news: [News] = [],
            page: Int = 1,
            isLoading: Bool = true,
            showShareSheet: Bool = false,
            showVpnWarningBackground: Bool = false
        ) {
            self.alert = alert
            self.news = news
            self.page = page
            self.isLoading = isLoading
            self.showShareSheet = showShareSheet
            self.showVpnWarningBackground = showVpnWarningBackground
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction {
        case menuTapped
        case newsTapped(News)
        case cellMenuOpened(NewsPreview, NewsListRowMenuAction) // RELEASE: Should it be a delegate?
        case onTask
        case onRefresh
        case onLoadMoreAppear
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
                return .none
            
            case .newsTapped:
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
                return .run { [page = state.page] send in
                    // RELEASE: Better way to hold for 1 sec?
                    let startTime = DispatchTime.now()
                    let result = await Result { try await newsClient.newsList(page: page) }
                    let endTime = DispatchTime.now()
                    let timeInterval = Int(Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds))
                    try await Task.sleep(for: .nanoseconds(1_000_000_000 - timeInterval))
                    await send(._newsResponse(result))
                }
                
            case .onLoadMoreAppear:
                state.page += 1
                return .run { [page = state.page] send in
                    let result = await Result { try await newsClient.newsList(page: page) }
                    await send(._newsResponse(result))
                }
                
            case let ._newsResponse(.success(previews)):
                state.isLoading = false
                let news = previews.map { News(preview: $0) }
                if state.page == 1 {
                    state.news = news
                } else {
                    state.news.append(contentsOf: news)
                }
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
        TextState("Whoops!")
    } actions: {
        ButtonState(action: .openCaptcha) {
            TextState("Show captcha")
        }
        ButtonState(role: .cancel, action: .cancel) {
            TextState("OK")
        }
    } message: {
        TextState("Looks like you have your VPN on or not located in Russia so you need to enter captcha. At this moment captcha validation works in test mode so it's recommended to disable vpn instead.")
    }
}
