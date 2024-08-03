//
//  MenuFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import Foundation
import ComposableArchitecture
import TCAExtensions
import Models

@Reducer
public struct MenuFeature {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var alert: AlertState<Never>?
        public var loggedIn = false
        
        public init(
            alert: AlertState<Never>? = nil,
            loggedIn: Bool = false
        ) {
            self.alert = alert
            self.loggedIn = loggedIn
        }
    }
    
    // MARK: - Action
    
    public enum Action {
        case alert(PresentationAction<Never>)
        case notImplementedFeatureTapped
        case profileTapped
        case settingsTapped
        case appAuthorButtonTapped
        case telegramChangelogButtonTapped
        case telegramChatButtonTapped
        case githubButtonTapped
    }
    
    // MARK: - Dependencies
    
    
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .alert:
                return .none
                
            case .notImplementedFeatureTapped:
                state.alert = .notImplemented
                return .none
                
            case .profileTapped:
                return .none
                
            case .settingsTapped:
                return .none
                
            case .appAuthorButtonTapped:
                return .run { _ in
                    await open(url: Links._4pdaAuthor)
                }
                
            case .telegramChangelogButtonTapped:
                return .run { _ in
                    await open(url: Links.telegramChangelog)
                }
                
            case .telegramChatButtonTapped:
                return .run { _ in
                    await open(url: Links.telegramChat)
                }
                
            case .githubButtonTapped:
                return .run { _ in
                    await open(url: Links.github)
                }
            }
        }
        .ifLet(\.alert, action: \.alert)
    }
}
