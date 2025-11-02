//
//  LogStoreFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 18.09.2025.
//

import SwiftUI
import ComposableArchitecture
import OSLog

@Reducer
public struct LogStoreFeature: Reducer, Sendable {
    
    public init() {}
    
    @ObservableState
    public struct State: Equatable {
        var logs: [String] = []
        var isLoading = true
        public init() {}
    }
    
    public enum Action {
        case onAppear
        case loaded([String])
    }
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    do {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "HH:mm:ss.SSS"
                        
                        let store = try OSLogStore(scope: .currentProcessIdentifier)
                        let position = store.position(timeIntervalSinceLatestBoot: 1)
                        
                        let logs = try store
                            .getEntries(at: position)
                            .compactMap { $0 as? OSLogEntryLog }
                            .filter { $0.subsystem == "pdapi" || $0.category == "App" }
                            .sorted(by: { $0.date > $1.date })
                            .map { "[\(formatter.string(from: $0.date))] \($0.composedMessage)" }
                        
                        await send(.loaded(logs))
                    } catch {
                        await send(.loaded([]))
                    }
                }
            case let .loaded(logs):
                state.logs = logs
                state.isLoading = false
            }
            return .none
        }
    }
}

public struct LogStoreScreen: View {
    public let store: StoreOf<LogStoreFeature>
    public init(store: StoreOf<LogStoreFeature>) {
        self.store = store
    }
    public var body: some View {
        WithPerceptionTracking {
            ScrollView(.vertical) {
                ForEach(store.logs, id: \.self) { log in
                    Text(log)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 4)
                }
            }
            .background {
                if store.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
}
