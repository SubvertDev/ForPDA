//
//  HistoryScreen.swift
//  ForPDA
//
//  Created by Xialtal on 8.11.24.
//

import SwiftUI
import ComposableArchitecture
import PageNavigationFeature
import SFSafeSymbols
import SharedUI
import Models

public struct HistoryScreen: View {
    
    @Perception.Bindable public var store: StoreOf<HistoryFeature>
    @Environment(\.tintColor) private var tintColor
    
    public init(store: StoreOf<HistoryFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color.Background.primary
                    .ignoresSafeArea()
                
                if !store.isLoading {
                    VStack(spacing: 1) {
                        if store.pageNavigation.shouldShow {
                            PageNavigation(store: store.scope(state: \.pageNavigation, action: \.pageNavigation))
                        }
                        
                        List(store.history, id: \.hashValue) { history in
                            HistorySection(history: history)
                        }
                        .scrollContentBackground(.hidden)
                    }
                } else {
                    PDALoader()
                        .frame(width: 24, height: 24)
                }
            }
            .navigationTitle(Text("History", bundle: .module))
            .navigationBarTitleDisplayMode(.large)
            .task {
                store.send(.onTask)
            }
        }
    }
    
    // MARK: - History Section
    
    private func HistorySection(history: HistoryRow) -> some View {
        Section {
            ForEach(history.topics) { topic in
                Row(title: topic.name, lastPost: topic.lastPost, unread: topic.isUnread) {
                    store.send(.topicTapped(id: topic.id))
                }
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        } header: {
            Header(title: history.seenDate.formattedDateOnly())
        }
        .listRowBackground(Color.Background.teritary)
    }
    
    // MARK: - Row
    
    @ViewBuilder
    private func Row(
        title: String,
        lastPost: TopicInfo.LastPost? = nil,
        unread: Bool,
        action: @escaping () -> Void = {}
    ) -> some View {
        HStack(spacing: 0) { // Hacky HStack to enable tap animations
            Button {
                action()
            } label: {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        RichText(
                            text: NSAttributedString(string: title),
                            font: .body,
                            foregroundStyle: Color.Labels.primary
                        )
                        
                        if let lastPost {
                            HStack(spacing: 0) {
                                Text(lastPost.formattedDate, bundle: .models)
                                    .font(.caption)
                                    .foregroundStyle(Color.Labels.secondary)
                                    .padding(.trailing, 16)
                                
                                Image(systemSymbol: .person)
                                    .font(.caption)
                                    .padding(.trailing, 4)
                                
                                RichText(
                                    text: NSAttributedString(string: lastPost.username),
                                    font: .caption,
                                    foregroundStyle: Color.Labels.secondary
                                )
                            }
                        }
                    }
                    
                    Spacer(minLength: 0)
                    
                    if unread {
                        Circle()
                            .font(.title2)
                            .foregroundStyle(tintColor)
                            .frame(width: 8)
                            .padding(.trailing, 12)
                    }
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        .buttonStyle(.plain)
        .frame(minHeight: 60)
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private func Header(title: LocalizedStringKey) -> some View {
        Text(title, bundle: .module)
            .font(.subheadline)
            .foregroundStyle(Color.Labels.teritary)
            .textCase(nil)
            .offset(x: 0)
            .padding(.bottom, 4)
    }
}

// MARK: - Extensions

private extension Date {

    func formattedDateOnly() -> LocalizedStringKey {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"

        if Calendar.current.isDateInToday(self) {
            return LocalizedStringKey("Today")
        } else if Calendar.current.isDateInYesterday(self) {
            return LocalizedStringKey("Yesterday")
        }
        
        return LocalizedStringKey("\(formatter.string(from: self))")
    }
}

// MARK: - Extensions

extension Bundle {
    static var models: Bundle? {
        return Bundle.allBundles.first(where: { $0.bundlePath.contains("Models") })
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        HistoryScreen(
            store: Store(
                initialState: HistoryFeature.State()
            ) {
                HistoryFeature()
            }
        )
    }
}
