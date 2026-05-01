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
import BBBuilder
import FormFeature
import ForumStatFeature
import ForumMoveFeature
import TopicEditFeature

@ViewAction(for: ForumFeature.self)
public struct ForumScreen: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<ForumFeature>
    @Environment(\.tintColor) private var tintColor
    @State private var navigationMinimized = false
    
    private var shouldShowInlineNavigation: Bool {
        let isAnyFloatingNavigationEnabled = store.appSettings.floatingNavigation || store.appSettings.experimentalFloatingNavigation
        return store.pageNavigation.shouldShow && (!isLiquidGlass || !isAnyFloatingNavigationEnabled)
    }
    
    private var shouldShowFloatingNavigation: Bool {
        return isLiquidGlass && store.appSettings.floatingNavigation && !store.appSettings.experimentalFloatingNavigation
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
                        if let globalAnnouncement = forum.globalAnnouncementAttributed {
                            GlobalAnnouncementRow(announce: globalAnnouncement)
                        }
                        
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
                    ._inScrollContentDetector(isEnabled: shouldShowFloatingNavigation, state: $navigationMinimized)
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
            .navigations(store: store)
            .safeAreaInset(edge: .bottom) {
                if shouldShowFloatingNavigation {
                    PageNavigation(
                        store: store.scope(state: \.pageNavigation, action: \.pageNavigation),
                        minimized: $navigationMinimized
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
            .toolbar {
                ToolbarItem {
                    Button {
                        send(.searchButtonTapped)
                    } label: {
                        Image(systemSymbol: .magnifyingglass)
                            .foregroundStyle(foregroundStyle())
                    }
                }
                
                if #available(iOS 26.0, *) {
                    ToolbarSpacer()
                }
                
                ToolbarItem {
                    OptionsMenu()
                }
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
                if forum.canCreateTopic {
                    Section {
                        ContextButton(text: LocalizedStringResource("Create Topic", bundle: .module), symbol: .plusCircle) {
                            send(.contextOptionMenu(.createTopic))
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
    
    // MARK: - Global Announcement Row
    
    @ViewBuilder
    private func GlobalAnnouncementRow(announce: NSAttributedString) -> some View {
        RichText(text: announce, onUrlTap: { url in
            send(.globalAnnouncementUrlTapped(url))
        })
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background {
            if #available(iOS 26, *) {
                ConcentricRectangle()
                    .fill(Color(.Background.teritary))
            } else {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.Background.teritary))
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 0, trailing: 0))
    }
    
    // MARK: - Topics
    
    @ViewBuilder
    private func TopicsSection(topics: [TopicInfo], pinned: Bool) -> some View {
        Section {
            if store.sectionsExpandState.value(for: pinned ? .pinnedTopics : .topics) {
                Navigation(pinned: pinned)
                
                ForEach(Array(topics.enumerated()), id: \.element) { index, topic in
                    WithPerceptionTracking {
                        let radius: CGFloat = isLiquidGlass ? 24 : 10
                        TopicRow(
                            title: .plain(topic.name),
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
                                
                                if topic.canModerate {
                                    TopicToolsContextMenu(topic: topic)
                                }
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
                
                if topic.canEdit {
                    ContextButton(text: LocalizedStringResource("Edit", bundle: .module), symbol: .squareAndPencil) {
                        send(.contextTopicMenu(.edit, topic))
                    }
                }
            }
        }
    }
    
    // MARK: - Topic Tools Context Menu
    
    @ViewBuilder
    private func TopicToolsContextMenu(topic: TopicInfo) -> some View {
        Menu {
            ContextButton(
                text: topic.isPinned
                ? LocalizedStringResource("Unpin", bundle: .module)
                : LocalizedStringResource("Pin", bundle: .module),
                symbol: topic.isPinned ? .pinFill : .pin
            ) {
                send(.contextTopicToolsMenu(.modify(.pin, topic.id, !topic.isPinned)))
            }
            
            ContextButton(
                text: topic.isHidden
                ? LocalizedStringResource("Remove Hide", bundle: .module)
                : LocalizedStringResource("Hide", bundle: .module),
                symbol: topic.isHidden ? .eyeSlashFill : .eyeSlash
            ) {
                send(.contextTopicToolsMenu(.modify(.hide, topic.id, !topic.isHidden)))
            }
            
            ContextButton(
                text: topic.isClosed
                ? LocalizedStringResource("Open", bundle: .module)
                : LocalizedStringResource("Close", bundle: .module),
                symbol: topic.isClosed ? .lockFill : .lock
            ) {
                send(.contextTopicToolsMenu(.modify(.close, topic.id, !topic.isClosed)))
            }
            
            if topic.canDelete {
                ContextButton(text: LocalizedStringResource("Delete", bundle: .module), symbol: .trash) {
                    send(.contextTopicToolsMenu(.modify(.delete, topic.id, false)))
                }
            }
            
            ContextButton(
                text: LocalizedStringResource("Move", bundle: .module),
                symbol: .arrowRight
            ) {
                send(.contextTopicToolsMenu(.move(topic.id)))
            }
        } label: {
            HStack {
                Text("Tools", bundle: .module)
                Image(systemSymbol: .shield)
            }
        }
    }
    
    // MARK: - Navigation
    
    @ViewBuilder
    private func Navigation(pinned: Bool) -> some View {
        if !pinned, shouldShowInlineNavigation {
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
                    WithPerceptionTracking {
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
        
        if store.isUserAuthorized, isUnread {
            ContextButton(text: LocalizedStringResource("Mark Read", bundle: .module), symbol: .checkmarkCircle) {
                send(.contextCommonMenu(.markRead, id, isForum))
            }
        }
        
        Section {
            if store.isUserAuthorized {
                ContextButton(
                    text: isFavorite
                    ? LocalizedStringResource("Remove from favorites", bundle: .module)
                    : LocalizedStringResource("Add to favorites", bundle: .module),
                    symbol: isFavorite ? .starFill : .star
                ) {
                    send(.contextCommonMenu(.setFavorite(isFavorite), id, isForum))
                }
            }
            
            if isForum {
                ContextButton(text: LocalizedStringResource("About Forum", bundle: .module), symbol: .infoCircle) {
                    send(.contextCommonMenu(.stat, id, isForum))
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

// MARK: - Navigation Modifier

struct NavigationModifier: ViewModifier {
    
    @Perception.Bindable private var store: StoreOf<ForumFeature>
    @Environment(\.tintColor) private var tintColor
    
    private var title: String {
        return store.forumName ?? String(localized: "Loading...", bundle: .module)
    }
    
    init(store: StoreOf<ForumFeature>) {
        self.store = store
    }
    
    func body(content: Content) -> some View {
        WithPerceptionTracking {
            content
                .navigationTitle(Text(title))
                ._toolbarTitleDisplayMode(.large)
                .modifier(FullScreenCoverModifier(store: store))
                .modifier(SheetModifier(store: store))
        }
    }
    
    struct FullScreenCoverModifier: ViewModifier {
        @Perception.Bindable private var store: StoreOf<ForumFeature>
        @Environment(\.tintColor) private var tintColor
        
        init(store: StoreOf<ForumFeature>) {
            self.store = store
        }
        
        func body(content: Content) -> some View {
            WithPerceptionTracking {
                content
                    .fullScreenCover(item: $store.scope(state: \.destination?.form, action: \.destination.form)) { store in
                        NavigationStack {
                            FormScreen(store: store)
                        }
                    }
            }
        }
    }
    
    struct SheetModifier: ViewModifier {
        @Perception.Bindable private var store: StoreOf<ForumFeature>
        @Environment(\.tintColor) private var tintColor
        
        init(store: StoreOf<ForumFeature>) {
            self.store = store
        }
        
        func body(content: Content) -> some View {
            WithPerceptionTracking {
                content
                    .sheet(item: $store.scope(state: \.destination?.stat, action: \.destination.stat)) { store in
                        NavigationStack {
                            ForumStatView(store: store)
                        }
                    }
                    .sheet(item: $store.scope(state: \.destination?.edit, action: \.destination.edit)) { store in
                        NavigationStack {
                            TopicEditView(store: store)
                        }
                    }
                    .fittedSheet(
                        item: $store.scope(state: \.destination?.move, action: \.destination.move),
                        embedIntoNavStack: true
                    ) { store in
                        ForumMoveView(store: store)
                    }
            }
        }
    }
}

// MARK: - Extensions

extension Bundle {
    static var models: Bundle? {
        return Bundle.allBundles.first(where: { $0.bundlePath.contains("Models") })
    }
}

extension View {
    func navigations(store: StoreOf<ForumFeature>) -> some View {
        self.modifier(NavigationModifier(store: store))
    }
}

extension Forum {
    var globalAnnouncementAttributed: NSAttributedString? {
        guard !globalAnnouncement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return BBRenderer().render(text: globalAnnouncement)
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
            }
        )
    }
}
