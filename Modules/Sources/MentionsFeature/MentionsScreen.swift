//
//  MentionsScreen.swift
//  ForPDA
//
//  Created by Codex on 19.02.2026.
//

import SwiftUI
import ComposableArchitecture
import PageNavigationFeature
import SFSafeSymbols
import SharedUI
import Models

@ViewAction(for: MentionsFeature.self)
public struct MentionsScreen: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<MentionsFeature>
    @Environment(\.tintColor) private var tintColor
    @State private var navigationMinimized = false
    
    private var shouldShowNavigation: Bool {
        let isAnyFloatingNavigationEnabled = store.appSettings.floatingNavigation || store.appSettings.experimentalFloatingNavigation
        return store.pageNavigation.shouldShow && (!isLiquidGlass || !isAnyFloatingNavigationEnabled)
    }
    
    // MARK: - Init
    
    public init(store: StoreOf<MentionsFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                if !store.mentions.isEmpty, !store.isLoading {
                    List {
                        Navigation()
                        
                        ForEach(store.mentions, id: \.self) { mention in
                            TopicRow(
                                title: .plain(mention.sourceName),
                                date: mention.mentionDate,
                                username: mention.username,
                                isClosed: false, // Not used for mentions
                                isUnread: false, // Not used for mentions
                                onAction: { _ in
                                    send(.mentionTapped(mention))
                                }
                            )
                        }
                        .listRowBackground(Color(.Background.teritary))
                        
                        Navigation()
                    }
                    .scrollContentBackground(.hidden)
                    ._inScrollContentDetector(state: $navigationMinimized)
                } else if !store.isLoading {
                    EmptyMentions()
                }
            }
            .animation(.default, value: store.mentions)
            .navigationTitle(Text("Mentions", bundle: .module))
            ._toolbarTitleDisplayMode(.large)
            .safeAreaInset(edge: .bottom) {
                if isLiquidGlass,
                   store.appSettings.floatingNavigation,
                   !store.appSettings.experimentalFloatingNavigation {
                    PageNavigation(
                        store: store.scope(state: \.pageNavigation, action: \.pageNavigation),
                        minimized: $navigationMinimized
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
            .overlay {
                if store.isLoading {
                    PDALoader()
                        .frame(width: 24, height: 24)
                }
            }
            .onAppear {
                send(.onAppear)
            }
        }
    }
    
    // MARK: - Page Navigation
    
    @ViewBuilder
    private func Navigation() -> some View {
        if shouldShowNavigation {
            PageNavigation(store: store.scope(state: \.pageNavigation, action: \.pageNavigation))
                .listRowBackground(Color(.Background.primary))
        }
    }
    
    // MARK: - Empty Mentions
    
    @ViewBuilder
    private func EmptyMentions() -> some View {
        VStack(spacing: 0) {
            Image(systemSymbol: .at)
                .font(.title)
                .foregroundStyle(tintColor)
                .frame(width: 48, height: 48)
                .padding(.bottom, 6)
            
            Text("No mentions", bundle: .module)
                .font(.title3)
                .bold()
                .foregroundColor(.primary)
                .padding(.bottom, 6)
            
            Text("When someone mentions you in forum topics, it will appear here.", bundle: .module)
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.7)
        }
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

// MARK: - Previews

#Preview {
    NavigationStack {
        MentionsScreen(
            store: Store(
                initialState: MentionsFeature.State()
            ) {
                MentionsFeature()
            }
        )
    }
}
