//
//  LogStoreFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 18.09.2025.
//

import SwiftUI
import ComposableArchitecture
import OSLog
import NotificationsClient
import Models

@Reducer
public struct LogStoreFeature: Reducer, Sendable {
    
    public init() {}
    
    public struct Log: Identifiable, Hashable {
        public let id = UUID()
        let message: String
        let date: Date
        let category: String
    }
    
    @ObservableState
    public struct State: Equatable {
        var logs: [Log] = []
        var isLoading = true
        public init() {}
    }
    
    public enum Action: ViewAction {
        public enum View {
            case onAppear
            case closeButtonTapped
            case sendTopicNotificationButtonTapped
        }
        case view(View)
        
        public enum Internal {
            case loaded([Log])
        }
        case `internal`(Internal)
    }
    
    @Dependency(\.dismiss) private var dismiss
    @Dependency(\.notificationsClient) private var notificationsClient
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
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
                            // .filter { $0.subsystem == "pdapi" || $0.category == "App" }
                            .filter { $0.subsystem == "com.subvert.forpda" }
                            .sorted(by: { $0.date < $1.date })
//                            .map { "[\(formatter.string(from: $0.date))] \($0.composedMessage)" }
                            .map { Log(message: $0.composedMessage, date: $0.date, category: $0.category) }
                        
                        await send(.internal(.loaded(logs)))
                    } catch {
                        await send(.internal(.loaded([])))
                    }
                }
                
            case .view(.closeButtonTapped):
                return .run { _ in await dismiss() }

            case .view(.sendTopicNotificationButtonTapped):
                return .run { _ in
                    let topicId = 1_104_159
                    let timestamp = Int(Date().timeIntervalSince1970 * 1_000)
                    let unread = Unread(
                        date: .now,
                        qmsUnreadCount: 0,
                        favoritesUnreadCount: 1,
                        mentionsUnreadCount: 0,
                        items: [
                            Unread.Item(
                                id: topicId,
                                name: "Test topic \(topicId)",
                                authorId: 0,
                                authorName: "ForPDA",
                                timestamp: timestamp,
                                unreadCount: 0,
                                category: .topic
                            )
                        ]
                    )
                    await notificationsClient.showUnreadNotifications(unread, skipCategories: [])
                }
                
            case let .internal(.loaded(logs)):
                state.logs = logs
                state.isLoading = false
            }
            return .none
        }
    }
}

@ViewAction(for: LogStoreFeature.self)
public struct LogStoreScreen: View {
    
    public let store: StoreOf<LogStoreFeature>
    
    public init(store: StoreOf<LogStoreFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ScrollView(.vertical) {
                Button(String("Notify 1104159")) { send(.sendTopicNotificationButtonTapped) }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 8)

                ForEach(store.logs) { log in
                    VStack(spacing: 2) {
                        Text(verbatim: "[\(log.date.formatted())] \(log.category)")
                            .font(.subheadline)
                            .foregroundStyle(.black.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(log.message)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.bottom, 4)
                }
            }
            .navigationTitle(Text(verbatim: "Logs"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { send(.closeButtonTapped) }
                }
            }
            .background {
                if store.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
            .onAppear {
                send(.onAppear)
            }
        }
    }
}
