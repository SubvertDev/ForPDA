//
//  SettingsFeature.swift
//
//
//  Created by Ilia Lubianoi on 12.05.2024.
//

import UIKit
import ComposableArchitecture
import CacheClient
import TCAExtensions
import Models

@Reducer
public struct SettingsFeature: Sendable {
    
    public init() {}
    
    // MARK: - Destinations
    
    @Reducer(state: .equatable)
    public enum Destination {
        case alert(AlertState<SettingsFeature.Action.Alert>)
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var destination: Destination.State?
        
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
        }
    }
    
    // MARK: - Action
    
    public enum Action {
        case languageButtonTapped
        case themeButtonTapped
        case safariExtensionButtonTapped
        case clearCacheButtonTapped
        case checkVersionsButtonTapped
        
        case _somethingWentWrong(any Error)
        
        // TODO: Different alerts?
        case destination(PresentationAction<Destination.Action>)
        public enum Alert: Equatable {
            case openSettings
            case clearCache
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.cacheClient) var cacheClient
    @Dependency(\.openURL) var openURL
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .languageButtonTapped:
                return .run { _ in
                    guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                    await open(url: settingsURL)
                }
                
            case .themeButtonTapped:
                state.destination = .alert(.notImplemented)
                return .none
                
            case .safariExtensionButtonTapped:
                // TODO: Not working anymore, check other solutions
                // openURL(URL(string: "App-Prefs:SAFARI&path=WEB_EXTENSIONS")!)
                state.destination = .alert(.safariExtension)
                return .none
                
            case .clearCacheButtonTapped:
                state.destination = .alert(.clearCache)
                return .none
                
            case .checkVersionsButtonTapped:
                return .run { _ in
                    // TODO: Move URL to models
                    await open(url: Links.githubReleases)
                }
                
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
                
            case .destination:
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
