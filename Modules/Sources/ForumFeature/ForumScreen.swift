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

@ViewAction(for: ForumFeature.self)
public struct ForumScreen: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<ForumFeature>
    @Environment(\.tintColor) private var tintColor
    @State private var navigationMinimized = false
    
    private var shouldShowNavigation: Bool {
        let isAnyFloatingNavigationEnabled = store.appSettings.floatingNavigation || store.appSettings.experimentalFloatingNavigation
        return store.pageNavigation.shouldShow && (!isLiquidGlass || !isAnyFloatingNavigationEnabled)
    }
    
    // MARK: - Init
    
    public init(store: StoreOf<ForumFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
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
                    ._inScrollContentDetector(state: $navigationMinimized)
                    .refreshable {
                        await send(.onRefresh).finish()
                    }
                } else {
                    PDALoader()
                        .frame(width: 24, height: 24)
                }
            }
            .animation(.default, value: store.forum)
            .animation(.default, value: store.sectionsExpandState)
            .navigationTitle(Text(store.forumName ?? "Загрузка..."))
            ._toolbarTitleDisplayMode(.large)
            ._safeAreaBar(edge: .bottom) {
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
            .toolbar {
                OptionsMenu()
            }
            .onFirstAppear {
                send(.onFirstAppear)
            } onNextAppear: {
                send(.onNextAppear)
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
                .foregroundStyle(foregroundStyle())
        }
    }
    
    @available(iOS, deprecated: 26.0)
    private func foregroundStyle() -> AnyShapeStyle {
        if isLiquidGlass {
            return AnyShapeStyle(.foreground)
        } else {
            return AnyShapeStyle(tintColor)
        }
    }
    
    // MARK: - Topics
    
    @ViewBuilder
    private func TopicsSection(topics: [TopicInfo], pinned: Bool) -> some View {
        Section {
            if store.sectionsExpandState.value(for: pinned ? .pinnedTopics : .topics) {
                Navigation(pinned: pinned)
                
                ForEach(Array(topics.enumerated()), id: \.element) { index, topic in
                    let radius: CGFloat = isLiquidGlass ? 24 : 10
                    TopicRow(
                        title: topic.name,
                        date: topic.lastPost.date,
                        username: topic.lastPost.username,
                        isClosed: topic.isClosed,
                        isUnread: topic.isUnread
                    ) { unreadTapped in
                        send(.topicTapped(topic, showUnread: unreadTapped))
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
                                topLeadingRadius: index == 0 ? radius : 0, bottomLeadingRadius: index == topics.count - 1 ? radius : 0,
                                bottomTrailingRadius: index == topics.count - 1 ? radius : 0, topTrailingRadius: index == 0 ? radius : 0
                            ))
                    )
                }
                .alignmentGuide(.listRowSeparatorLeading) { _ in return 0 }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                
                Navigation(pinned: pinned)
            }
        } header: {
            Header(
                title: pinned ? "Pinned topics" : "Topics",
                section: pinned ? .pinnedTopics : .topics
            )
        }
        .listRowBackground(Color(.Background.teritary))
    }
    
    // MARK: - Topic Context Menu
    
    @ViewBuilder
    private func TopicContextMenu(topic: TopicInfo) -> some View {
        Section {
            ContextButton(text: LocalizedStringResource("Open", bundle: .module), symbol: .eye) {
                send(.contextTopicMenu(.open, topic))
            }
            
            Section {
                ContextButton(text: LocalizedStringResource("Go To End", bundle: .module), symbol: .chevronRight2) {
                    send(.contextTopicMenu(.goToEnd, topic))
                }
            }
        }
    }
    
    // MARK: - Navigation
    
    @ViewBuilder
    private func Navigation(pinned: Bool) -> some View {
        if !pinned, shouldShowNavigation {
            PageNavigation(store: store.scope(state: \.pageNavigation, action: \.pageNavigation))
                .listRowBackground(Color.clear)
                .padding(.bottom, 4)
        }
    }
    
    // MARK: - Subforums section
    
    @ViewBuilder
    private func SubforumsSection(subforums: [ForumInfo]) -> some View {
        Section {
            if store.sectionsExpandState.value(for: .subforums) {
                ForEach(subforums) { forum in
                    ForumRow(title: forum.name, isUnread: forum.isUnread) {
                        if let redirectUrl = forum.redirectUrl {
                            send(.subforumRedirectTapped(redirectUrl))
                        } else {
                            send(.subforumTapped(forum))
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
            }
        } header: {
            Header(title: "Subforums", section: .subforums)
        }
        .listRowBackground(Color(.Background.teritary))
    }
    
    // MARK: - Announcements section
    
    @ViewBuilder
    private func AnnouncmentsSection(announcements: [AnnouncementInfo]) -> some View {
        Section {
            if store.sectionsExpandState.value(for: .announcements) {
                ForEach(announcements) { announcement in
                    ForumRow(title: announcement.name, isUnread: false) {
                        send(.announcementTapped(id: announcement.id, name: announcement.name))
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
        } header: {
            Header(title: "Announcements", section: .announcements)
        }
        .listRowBackground(Color(.Background.teritary))
    }
    
    @ViewBuilder
    private func CommonContextMenu(id: Int, isFavorite: Bool, isUnread: Bool, isForum: Bool) -> some View {
        ContextButton(text: LocalizedStringResource("Copy Link", bundle: .module), symbol: .docOnDoc) {
            send(.contextCommonMenu(.copyLink, id, isForum))
        }
        
        ContextButton(text: LocalizedStringResource("Open In Browser", bundle: .module), symbol: .safari) {
            send(.contextCommonMenu(.openInBrowser, id, isForum))
        }
        
        if store.isUserAuthorized {
            if isUnread {
                ContextButton(text: LocalizedStringResource("Mark Read", bundle: .module), symbol: .checkmarkCircle) {
                    send(.contextCommonMenu(.markRead, id, isForum))
                }
            }
            
            Section {
                ContextButton(
                    text: isFavorite
                    ? LocalizedStringResource("Remove from favorites", bundle: .module)
                    : LocalizedStringResource("Add to favorites", bundle: .module),
                    symbol: isFavorite ? .starFill : .star
                ) {
                    send(.contextCommonMenu(.setFavorite(isFavorite), id, isForum))
                }
            }
        }
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private func Header(
        title: LocalizedStringKey,
        section: ForumFeature.SectionExpand.Kind
    ) -> some View {
        Button {
            send(.sectionExpandTapped(section))
        } label: {
            Text(title, bundle: .module)
                .font(.subheadline)
                .foregroundStyle(Color(.Labels.teritary))
                .textCase(nil)
                .offset(x: -16)
            
            Spacer()
            
            Image(systemSymbol: .chevronUp)
                .font(.body)
                .foregroundStyle(Color(.Labels.quaternary))
                .rotationEffect(.degrees(store.sectionsExpandState.value(for: section) ? 0 : -180))
                .offset(x: 16)
        }
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
