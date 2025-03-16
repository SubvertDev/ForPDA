//
//  ForumScreen.swift
//  ForPDA
//
//  Created by Xialtal on 25.10.24.
//

import SwiftUI
import ComposableArchitecture
import PageNavigationFeature
import SFSafeSymbols
import SharedUI
import Models

public struct ForumScreen: View {
    
    @Perception.Bindable public var store: StoreOf<ForumFeature>
    @Environment(\.tintColor) private var tintColor
    
    public init(store: StoreOf<ForumFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                if let forum = store.forum, !store.isLoadingTopics {
                    List {
                        if !forum.subforums.isEmpty {
                            SubforumsSection(subforums: forum.subforums)
                        }
                        
                        if !forum.announcements.isEmpty {
                            AnnouncmentsSection(announcements: forum.announcements)
                        }

                        if !store.topicsPinned.isEmpty {
                            TopicsSection(topics: store.topicsPinned, pinned: true)
                        }
                        
                        if !store.topics.isEmpty {
                            TopicsSection(topics: store.topics, pinned: false)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        await store.send(.onRefresh).finish()
                    }
                } else {
                    PDALoader()
                        .frame(width: 24, height: 24)
                }
            }
            .animation(.default, value: store.forum)
            .navigationTitle(Text(store.forumName ?? "Загрузка..."))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                OptionsMenu()
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
    
    // MARK: - Options Menu
    
    @ViewBuilder
    private func OptionsMenu() -> some View {
        Menu {
            if let forum = store.forum {
                CommonContextMenu(
                    id: forum.id,
                    isFavorite: forum.isFavorite,
                    isUnread: false,
                    isForum: true
                )
            }
        } label: {
            Image(systemSymbol: .ellipsisCircle)
        }
    }
    
    // MARK: - Topics
    
    @ViewBuilder
    private func TopicsSection(topics: [TopicInfo], pinned: Bool) -> some View {
        Section {
            Navigation(pinned: pinned)
            
            ForEach(Array(topics.enumerated()), id: \.element) { index, topic in
                Row(title: topic.name, lastPost: topic.lastPost, closed: topic.isClosed, unread: topic.isUnread) {
                    store.send(.topicTapped(id: topic.id, offset: 0))
                }
                .contextMenu {
                    TopicContextMenu(topicId: topic.id)
                    
                    Section {
                        CommonContextMenu(id: topic.id, isFavorite: topic.isFavorite, isUnread: topic.isUnread, isForum: false)
                    }
                }
                .listRowBackground(
                    Color(.Background.teritary)
                        .clipShape(.rect(
                            topLeadingRadius: index == 0 ? 10 : 0, bottomLeadingRadius: index == topics.count - 1 ? 10 : 0,
                            bottomTrailingRadius: index == topics.count - 1 ? 10 : 0, topTrailingRadius: index == 0 ? 10 : 0
                        ))
                )
            }
            .alignmentGuide(.listRowSeparatorLeading) { _ in return 0 }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            
            Navigation(pinned: pinned)
        } header: {
            Header(title: pinned ? "Pinned topics" : "Topics")
        }
        .listRowBackground(Color(.Background.teritary))
    }
    
    // MARK: - Topic Context Menu
    
    @ViewBuilder
    private func TopicContextMenu(topicId: Int) -> some View {
        Section {
            ContextButton(text: "Open", symbol: .eye, bundle: .module) {
                store.send(.contextTopicMenu(.open, topicId))
            }
            
            Section {
                ContextButton(text: "Go To End", symbol: .chevronRight2, bundle: .module) {
                    store.send(.contextTopicMenu(.goToEnd, topicId))
                }
            }
        }
    }
    
    // MARK: - Navigation
    
    @ViewBuilder
    private func Navigation(pinned: Bool) -> some View {
        if !pinned, store.pageNavigation.shouldShow {
            PageNavigation(store: store.scope(state: \.pageNavigation, action: \.pageNavigation))
                .listRowBackground(Color.clear)
                .padding(.bottom, 4)
        }
    }
    
    // MARK: - Subforums section
    
    @ViewBuilder
    private func SubforumsSection(subforums: [ForumInfo]) -> some View {
        Section {
            ForEach(subforums) { forum in
                Row(title: forum.name, unread: forum.isUnread) {
                    if let redirectUrl = forum.redirectUrl {
                        store.send(.subforumRedirectTapped(redirectUrl))
                    } else {
                        store.send(.subforumTapped(id: forum.id, name: forum.name))
                    }
                }
                .contextMenu {
                    Section {
                        CommonContextMenu(
                            id: forum.id,
                            isFavorite:forum.isFavorite,
                            isUnread: forum.isUnread,
                            isForum: true
                        )
                    }
                }
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        } header: {
            Header(title: "Subforums")
        }
        .listRowBackground(Color(.Background.teritary))
    }
    
    // MARK: - Announcements section
    
    @ViewBuilder
    private func AnnouncmentsSection(announcements: [AnnouncementInfo]) -> some View {
        Section {
            ForEach(announcements) { announcement in
                Row(title: announcement.name) {
                    store.send(.announcementTapped(id: announcement.id, name: announcement.name))
                }
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        } header: {
            Header(title: "Announcements")
        }
        .listRowBackground(Color(.Background.teritary))
    }
    
    @ViewBuilder
    private func CommonContextMenu(id: Int, isFavorite: Bool, isUnread: Bool, isForum: Bool) -> some View {
        ContextButton(text: "Copy Link", symbol: .docOnDoc, bundle: .module) {
            store.send(.contextCommonMenu(.copyLink, id, isForum))
        }
        
        ContextButton(text: "Open In Browser", symbol: .safari, bundle: .module) {
            store.send(.contextCommonMenu(.openInBrowser, id, isForum))
        }
        
        if store.isUserAuthorized {
            if isUnread {
                ContextButton(text: "Mark Read", symbol: .checkmarkCircle, bundle: .module) {
                    store.send(.contextCommonMenu(.markRead, id, isForum))
                }
            }
            
            Section {
                ContextButton(
                    text: isFavorite ? "Remove from favorites" : "Add to favorites",
                    symbol: isFavorite ? .starFill : .star,
                    bundle: .module
                ) {
                    store.send(.contextCommonMenu(.setFavorite(isFavorite), id, isForum))
                }
            }
        }
    }
    
    // MARK: - Row
    
    @ViewBuilder
    private func Row(
        title: String,
        lastPost: TopicInfo.LastPost? = nil,
        closed: Bool = false,
        unread: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 0) { // Hacky HStack to enable tap animations
            Button {
                action()
            } label: {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
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
                    
                    if closed {
                        Image(systemSymbol: .lock)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(Color(.Labels.secondary))
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
            .foregroundStyle(Color(.Labels.teritary))
            .textCase(nil)
            .offset(x: -16)
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
        ForumScreen(
            store: Store(
                initialState: ForumFeature.State.init(
                    forumId: 0,
                    forumName: "Test name"
                )
            ) {
                ForumFeature()
            } withDependencies: {
                $0.apiClient.getForum = { @Sendable _, _, _, _ in
                    return .finished()
                }
            }
        )
    }
}
