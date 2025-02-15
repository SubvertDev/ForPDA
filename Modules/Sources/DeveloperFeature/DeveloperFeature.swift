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
        
        public var lastBackgroundTaskInvokeTime: [TimeInterval] = []
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
        
        case _onCacheLoad([TimeInterval])
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
                    let timeIntervals = await cacheClient.getLastBackgroundTaskInvokeTime()
                    await send(._onCacheLoad(timeIntervals))
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
                
            case let ._onCacheLoad(timeIntervals):
                state.lastBackgroundTaskInvokeTime = timeIntervals
                return .none
            }
        }
    }
}

// MARK: - Screen

public struct DeveloperScreen: View {
    
    @Perception.Bindable public var store: StoreOf<DeveloperFeature>
    
    public init(store: StoreOf<DeveloperFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("ID: \(store.analyticsId)")
                    
                    ForEach(store.lastBackgroundTaskInvokeTime, id: \.self) { date in
                        Text("Refresh on \(date.formatted())")
                    }
                    
                    HStack(spacing: 8) {
                        Text("Is Mixpanel enabled: ")
                        Toggle("", isOn: $store.isAnalyticsEnabled)
                    }
                    
                    HStack(spacing: 8) {
                        Text("Is Sentry enabled: ")
                        Toggle("", isOn: $store.isCrashlyticsEnabled)
                    }
                    
                    Button("Send test crash to Sentry") {
                        store.send(.sendCrashButtonTapped)
                    }
                    
                    Spacer()
                }
                .padding(16)
            }
            .navigationTitle("Developer menu")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
    
}

#Preview {
    DeveloperScreen(store: Store(initialState: DeveloperFeature.State()) {
        DeveloperFeature()
    })
}

private var isDebug: Bool {
    #if DEBUG
        return true
    #else
        return false
    #endif
}
