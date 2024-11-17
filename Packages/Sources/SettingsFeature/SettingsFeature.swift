//
//  SettingsFeature.swift
//
//
//  Created by Ilia Lubianoi on 12.05.2024.
//

import UIKit
import ComposableArchitecture
import PasteboardClient
import CacheClient
import TCAExtensions
import PersistenceKeys
import Models

@Reducer
public struct SettingsFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - Destinations
    
    @Reducer(state: .equatable)
    public enum Destination {
        case alert(AlertState<SettingsFeature.Action.Alert>)
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Shared(.appSettings) public var appSettings: AppSettings
        
        @Presents public var destination: Destination.State?
        
        public var startPage: AppTab
        public var appColorScheme: AppColorScheme
        public var backgroundTheme: BackgroundTheme
        public var appTintColor: AppTintColor
        
        public var appVersionAndBuild: String {
            let info = Bundle.main.infoDictionary
            let version = info?["CFBundleShortVersionString"] as? String ?? "-1"
            let build = info?["CFBundleVersion"] as? String ?? "-1"
            return "\(version) (\(build))"
        }
        
        public var currentLanguage: String {
            guard let identifier = Locale.current.language.languageCode?.identifier else { return "Unknown" }
            switch identifier {
            case "en": return "English"
            case "ru": return "Русский"
            default:   return "Unknown"
            }
        }
        
        public init(
            destination: Destination.State? = nil
        ) {
            self.destination = destination

            self.startPage = _appSettings.startPage.wrappedValue
            self.appColorScheme = _appSettings.appColorScheme.wrappedValue
            self.backgroundTheme = _appSettings.backgroundTheme.wrappedValue
            self.appTintColor = _appSettings.appTintColor.wrappedValue
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case languageButtonTapped
        case schemeButtonTapped(AppColorScheme)
        case notificationsButtonTapped
        case onDeveloperMenuTapped
        case safariExtensionButtonTapped
        case copyDebugIdButtonTapped
        // case copyPushTokenButtonTapped
        case clearCacheButtonTapped
        case appDiscussionButtonTapped
        case telegramChangelogButtonTapped
        case telegramChatButtonTapped
        case githubButtonTapped
        case checkVersionsButtonTapped
        case notImplementedFeatureTapped
        
        case _somethingWentWrong(any Error)
        
        // TODO: Different alerts?
        case destination(PresentationAction<Destination.Action>)
        public enum Alert: Equatable {
            case openSettings
            case clearCache
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.pasteboardClient) var pasteboardClient
    @Dependency(\.cacheClient) var cacheClient
    @Dependency(\.openURL) var openURL
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case .languageButtonTapped:
                return .run { _ in
                    guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                    await open(url: settingsURL)
                }
                
            case let .schemeButtonTapped(scheme):
                state.appColorScheme = scheme
                return .run { [appSettings = state.$appSettings,
                               scheme = state.appColorScheme] _ in
                    await appSettings.withLock { $0.appColorScheme = scheme }
                }
                
            case .notificationsButtonTapped:
                return .none
                
            case .onDeveloperMenuTapped:
                return .none
                
            case .safariExtensionButtonTapped:
                // TODO: Not working anymore, check other solutions
                // openURL(URL(string: "App-Prefs:SAFARI&path=WEB_EXTENSIONS")!)
                state.destination = .alert(.safariExtension)
                return .none
                
            case .copyDebugIdButtonTapped:
                @Shared(.appStorage("analytics_id")) var analyticsId: String = UUID().uuidString
                pasteboardClient.copy(analyticsId)
                return .none
                
            // case .copyPushTokenButtonTapped:
            //     state.destination = .alert(.notImplemented)
            //     return .none
                
            case .clearCacheButtonTapped:
                state.destination = .alert(.clearCache)
                return .none
                
            case .appDiscussionButtonTapped:
                return .none
                
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
                
            case .checkVersionsButtonTapped:
                return .run { _ in
                    // TODO: Move URL to models
                    await open(url: Links.githubReleases)
                }
                
            case .notImplementedFeatureTapped:
                state.destination = .alert(.notImplemented)
                return .none
                
            case .destination(.presented(.alert(.openSettings))):
                return .run { _ in
                    // TODO: Test on iOS 16/17
                    await open(url: URL(string: "App-Prefs:")!)
                }
                
            case ._somethingWentWrong:
                state.destination = .alert(.somethingWentWrong)
                return .none
                
            case .destination(.presented(.alert(.clearCache))):
                return .run { send in
                    do {
                        try await cacheClient.removeAll()
                    } catch {
                        await send(._somethingWentWrong(error))
                    }
                }
                
            case .binding(\.appTintColor):
                return .run { [appSettings = state.$appSettings,
                               tint = state.appTintColor] _ in
                    await appSettings.withLock { $0.appTintColor = tint }
                }
                
            case .binding(\.backgroundTheme):
                state.backgroundTheme = .blue
                state.destination = .alert(.notImplemented)
                return .none
                
            case .binding(\.startPage):
                return .run { [appSettings = state.$appSettings,
                               page = state.startPage] _ in
                    await appSettings.withLock { $0.startPage = page }
                }
                
            case .destination, .binding:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        
        Analytics()
    }
}

// MARK: - Alert Extensions

private extension AlertState where Action == SettingsFeature.Action.Alert {
    
    // Safari Extension
    
    nonisolated(unsafe) static let safariExtension = AlertState {
        TextState("Instructions", bundle: .module)
    } actions: {
        ButtonState(action: .openSettings) {
            TextState("Open Settings", bundle: .module)
        }
        ButtonState(role: .cancel) {
            TextState("Cancel", bundle: .module)
        }
    } message: {
        TextState("You need to open Settings > Apps > Safari > Extensions > Open in ForPDA > Allow Extension", bundle: .module)
    }
    
    // Clear Cache
    
    nonisolated(unsafe) static let clearCache = AlertState {
        TextState("Clear Cache?", bundle: .module)
    } actions: {
        ButtonState(action: .clearCache) {
            TextState("OK", bundle: .module)
        }
        ButtonState(role: .cancel) {
            TextState("Cancel", bundle: .module)
        }
    }
}
