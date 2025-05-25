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
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                if !store.history.isEmpty, !store.isLoading {
                    List {
                        Navigation()
                        
                        ForEach(store.history, id: \.hashValue) { history in
                            HistorySection(history: history)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24))
                        
                        Navigation()
                    }
                    .scrollContentBackground(.hidden)
                } else if !store.isLoading {
                    EmptyHistory()
                }
            }
            .animation(.default, value: store.history)
            .navigationTitle(Text("History", bundle: .module))
            .navigationBarTitleDisplayMode(.large)
            .overlay {
                if store.isLoading {
                    PDALoader()
                        .frame(width: 24, height: 24)
                }
            }
            .task {
                store.send(.onTask)
            }
        }
    }
    
    // MARK: - Page Navigation
    
    @ViewBuilder
    private func Navigation() -> some View {
        if store.pageNavigation.shouldShow {
            PageNavigation(store: store.scope(state: \.pageNavigation, action: \.pageNavigation))
                .listRowBackground(Color(.Background.primary))
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
        .listRowBackground(Color(.Background.teritary))
    }
    
    // MARK: - Empty History
            
    @ViewBuilder
    private func EmptyHistory() -> some View {
        VStack(spacing: 0) {
            Image(systemSymbol: .clockArrowCirclepath)
                .font(.title)
                .foregroundStyle(tintColor)
                .frame(width: 48, height: 48)
                .padding(.bottom, 6)
            
            Text("No history", bundle: .module)
                .font(.title3)
                .bold()
                .foregroundColor(.primary)
                .padding(.bottom, 6)
            
            Text("View any topic in forum and it displays here.", bundle: .module)
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.7)
        }
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
                        if let lastPost {
                            Text(lastPost.formattedDate, bundle: Bundle.models)
                                .font(.caption)
                                .foregroundStyle(Color(.Labels.teritary))
                        }
                        
                        RichText(
                            text: AttributedString(title),
                            isSelectable: false,
                            font: .body,
                            foregroundStyle: Color(.Labels.primary)
                        )
                        
                        if let lastPost {
                            HStack(spacing: 4) {
                                Image(systemSymbol: .personCircle)
                                    .font(.caption)
                                    .foregroundStyle(Color(.Labels.secondary))
                                
                                RichText(
                                    text: AttributedString(lastPost.username),
                                    isSelectable: false,
                                    font: .caption,
                                    foregroundStyle: Color(.Labels.secondary)
                                )
                            }
                        }
                    }
                    
                    Spacer(minLength: 0)
                    
                    if unread {
                        Image(systemSymbol: .circleFill)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 10, height: 10)
                            .foregroundStyle(tintColor)
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
            .foregroundStyle(Color(.Labels.teritary))
            .textCase(nil)
            .offset(x: -16)
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
