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
import WriteFormFeature

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
                    .scrollDismissesKeyboard(.immediately)
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
            .fullScreenCover(item: $store.scope(state: \.writeForm, action: \.writeForm)) { store in
                NavigationStack {
                    WriteFormScreen(store: store)
                }
            }
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
                if forum.canCreateTopic {
                    Section {
                        ContextButton(text: "Create Topic", symbol: .plusCircle, bundle: .module) {
                            store.send(.contextOptionMenu(.createTopic))
                        }
                    }
                }
                
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
                TopicRow(
                    title: topic.name,
                    date: topic.lastPost.date,
                    username: topic.lastPost.username,
                    isClosed: topic.isClosed,
                    isUnread: topic.isUnread
                ) { unreadTapped in
                    store.send(.topicTapped(topic, showUnread: unreadTapped))
                }
                .contextMenu {
                    TopicContextMenu(topic: topic)
                    
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
    private func TopicContextMenu(topic: TopicInfo) -> some View {
        Section {
            ContextButton(text: "Open", symbol: .eye, bundle: .module) {
                store.send(.contextTopicMenu(.open, topic))
            }
            
            Section {
                ContextButton(text: "Go To End", symbol: .chevronRight2, bundle: .module) {
                    store.send(.contextTopicMenu(.goToEnd, topic))
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
                ForumRow(title: forum.name, isUnread: forum.isUnread) {
                    if let redirectUrl = forum.redirectUrl {
                        store.send(.subforumRedirectTapped(redirectUrl))
                    } else {
                        store.send(.subforumTapped(forum))
                    }
                }
                .contextMenu {
                    Section {
                        CommonContextMenu(
                            id: forum.id,
                            isFavorite: forum.isFavorite,
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
                ForumRow(title: announcement.name, isUnread: false) {
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
