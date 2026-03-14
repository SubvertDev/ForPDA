//
//  Developer.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 16.11.2024.
//

import SwiftUI
import ComposableArchitecture
import SharedUI
import CacheClient
import AnalyticsClient
import PersistenceKeys
import Models

enum TestError: Error {
    case test(String)
}

@Reducer
public struct DeveloperFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Shared(.appSettings) public var appSettings: AppSettings
        @Shared(.appStorage("analytics_id")) var analyticsId: String = UUID().uuidString
        
        public var backgroundTaskEntries: [BackgroundTaskEntry] = []
        public var isAnalyticsEnabled: Bool
        public var isCrashlyticsEnabled: Bool
        
        public init() {
            if isDebug {
                self.isAnalyticsEnabled = _appSettings.analyticsConfigurationDebug.isAnalyticsEnabled.wrappedValue
                self.isCrashlyticsEnabled = _appSettings.analyticsConfigurationDebug.isCrashlyticsEnabled.wrappedValue
            } else {
                self.isAnalyticsEnabled = _appSettings.analyticsConfigurationRelease.isAnalyticsEnabled.wrappedValue
                self.isCrashlyticsEnabled = _appSettings.analyticsConfigurationRelease.isCrashlyticsEnabled.wrappedValue
            }
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction {
        case onAppear
        case sendCrashButtonTapped
        case binding(BindingAction<State>)
        
        case _onCacheLoad([BackgroundTaskEntry])
    }
    
    // MARK: - Dependency
    
    @Dependency(\.cacheClient) private var cacheClient
    @Dependency(\.analyticsClient) private var analyticsClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                     let entries = cacheClient.getBackgroundTaskEntries()
                     await send(._onCacheLoad(entries))
                }
                
            case .sendCrashButtonTapped:
                return .run { _ in
                    analyticsClient.capture(TestError.test("This is a test error"))
                }
                
            case .binding(\.isAnalyticsEnabled):
                if isDebug {
                    state.$appSettings.analyticsConfigurationDebug.isAnalyticsEnabled.withLock { $0 = state.isAnalyticsEnabled }
                } else {
                    state.$appSettings.analyticsConfigurationRelease.isAnalyticsEnabled.withLock { $0 = state.isAnalyticsEnabled }
                }
                return .none
                
            case .binding(\.isCrashlyticsEnabled):
                if isDebug {
                    state.$appSettings.analyticsConfigurationDebug.isCrashlyticsEnabled.withLock { $0 = state.isCrashlyticsEnabled }
                } else {
                    state.$appSettings.analyticsConfigurationRelease.isCrashlyticsEnabled.withLock { $0 = state.isCrashlyticsEnabled }
                }
                return .none
                
            case .binding:
                return .none
                
            case let ._onCacheLoad(entries):
                state.backgroundTaskEntries = entries
                return .none
            }
        }
    }
}

// MARK: - Screen

public struct DeveloperScreen: View {
    
    @Bindable public var store: StoreOf<DeveloperFeature>
    
    public init(store: StoreOf<DeveloperFeature>) {
        self.store = store
    }
    
    public var body: some View {
        ZStack {
            Color(.Background.primary)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("ID: \(store.analyticsId)")
                    
                    HStack(spacing: 8) {
                        Text("Is analytics enabled: ")
                        Toggle("", isOn: $store.isAnalyticsEnabled)
                    }
                    
                    HStack(spacing: 8) {
                        Text("Is Sentry enabled: ")
                        Toggle("", isOn: $store.isCrashlyticsEnabled)
                    }
                    
                    Button("Send test crash to Sentry") {
                        store.send(.sendCrashButtonTapped)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(store.backgroundTaskEntries, id: \.self) { entry in
                            Text(verbatim: "[\(entry.date.formatted(date: .numeric, time: .standard))] \(entry.stage)")
                                .font(.caption)
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Developer menu")
        ._toolbarTitleDisplayMode(.inline)
        .onAppear {
            store.send(.onAppear)
        }
                
    }
    
}

private var isDebug: Bool {
    #if DEBUG
        return true
    #else
        return false
    #endif
}

// MARK: - Previews

#Preview {
    DeveloperScreen(store: Store(initialState: DeveloperFeature.State()) {
        DeveloperFeature()
    })
}
