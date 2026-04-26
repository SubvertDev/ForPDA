//
//  ForumPageScreen.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 07.11.2024.
//

import SwiftUI
import ComposableArchitecture
import PageNavigationFeature
import FormFeature
import SFSafeSymbols
import SharedUI
import NukeUI
import Models
import ParsingClient
import ReputationChangeFeature
import TopicBuilder
import GalleryFeature
import ForumStatFeature
import ForumMoveFeature

@ViewAction(for: TopicFeature.self)
public struct TopicScreen: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<TopicFeature>
    
    @Environment(\.tintColor) private var tintColor
    @State private var scrollProxy: ScrollViewProxy?
    @State private var scrollScale: CGFloat = 1
    @State private var showKarmaConfirmation = false
    @State private var navigationMinimized = false
    
    // MARK: - Computed Properties
    
    private var shouldShowTopNavigation: Bool {
        let shouldShow = store.topic != nil
        let isAnyFloatingNavigationEnabled = store.appSettings.floatingNavigation || store.appSettings.experimentalFloatingNavigation
        return shouldShow && (!isLiquidGlass || !isAnyFloatingNavigationEnabled)
    }
    
    private var shouldShowBottomNavigation: Bool {
        let shouldShow = store.topic != nil && !store.isLoadingTopic
        let isAnyFloatingNavigationEnabled = store.appSettings.floatingNavigation || store.appSettings.experimentalFloatingNavigation
        return shouldShow && (!isLiquidGlass || !isAnyFloatingNavigationEnabled)
    }
    
    private var shouldShowFloatingNavigation: Bool {
        return isLiquidGlass && store.appSettings.floatingNavigation && !store.appSettings.experimentalFloatingNavigation
    }
    
    private var isPollAvailable: Bool {
        let topicLoaded = store.topic != nil && !store.isLoadingTopic
        return topicLoaded && store.topic!.poll != nil
    }
    
    // MARK: - Init
    
    public init(store: StoreOf<TopicFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                ScrollViewReader { proxy in
                    WithPerceptionTracking {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                if shouldShowTopNavigation {
                                    Navigation()
                                }
                                
                                if !store.isLoadingTopic {
                                    Header()
                                    
                                    if let poll = store.topic?.poll {
                                        Poll(poll)
                                    }
                                    
                                    PostList()
                                }
                                
                                if shouldShowBottomNavigation {
                                    Navigation()
                                }
                            }
                            .padding(.bottom, 16)
                        }
                        ._inScrollContentDetector(isEnabled: shouldShowFloatingNavigation, state: $navigationMinimized)
                        .onAppear {
                            scrollProxy = proxy
                        }
                    }
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .refreshable {
                // Wrapper around finish() due to SwiftUI bug
                await Task { await send(.onRefresh).finish() }.value
            }
            .overlay {
                if store.topic == nil {
                    PDALoader()
                        .frame(width: 24, height: 24)
                }
            }
            .navigations(store: store)
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
            .onChange(of: store.postId)         { _ in Task { await scrollAndAnimate() } }
            .onChange(of: store.isLoadingTopic) { _ in Task { await scrollAndAnimate() } }
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
            if let topic = store.topic, store.isUserAuthorized, topic.canPost {
                Section {
                    ContextButton(text: LocalizedStringResource("Write Post", bundle: .module), symbol: .plusCircle) {
                        send(.contextMenu(.writePost))
                    }
                    
                    if let postTemplate = topic.postTemplateName {
                        ContextButton(text: LocalizedStringResource(stringLiteral: postTemplate), symbol: .plusApp) {
                            send(.contextMenu(.writePostWithTemplate))
                        }
                    }
                }
            }
            
            ContextButton(text: LocalizedStringResource("Copy Link", bundle: .module), symbol: .docOnDoc) {
                send(.contextMenu(.copyLink))
            }
            ContextButton(text: LocalizedStringResource("Open In Browser", bundle: .module), symbol: .safari) {
                send(.contextMenu(.openInBrowser))
            }
            
            if !store.pageNavigation.isLastPage {
                Section {
                    ContextButton(text: LocalizedStringResource("Go To End", bundle: .module), symbol: .chevronRight2) {
                        send(.contextMenu(.goToEnd))
                    }
                }
            }
            
            if let topic = store.topic, store.isUserAuthorized {
                Section {
                    ContextButton(
                        text: topic.isFavorite
                        ? LocalizedStringResource("Remove from favorites", bundle: .module)
                        : LocalizedStringResource("Add to favorites", bundle: .module),
                        symbol: topic.isFavorite ? .starFill : .star
                    ) {
                        send(.contextMenu(.setFavorite))
                    }
                    
                    ContextButton(text: LocalizedStringResource("About Topic", bundle: .module), symbol: .infoCircle) {
                        send(.contextMenu(.about))
                    }
                }
                
                if topic.canModerate {
                    Section {
                        ToolsOptionsMenu(topic: topic)
                        
                        Menu {
                            Picker(String(), selection: $store.postsFilter) {
                                ForEach(TopicPostsFilter.allCases) { mode in
                                    Text(mode.title, bundle: .module)
                                        .tag(mode)
                                }
                            }
                        } label: {
                            HStack {
                                Text("Posts Filter", bundle: .module)
                                Image(systemSymbol: .line3HorizontalDecrease)
                            }
                        }
                    }
                }
            }
        } label: {
            Image(systemSymbol: .ellipsisCircle)
                .foregroundStyle(foregroundStyle())
        }
    }
    
    // MARK: - Tools Options Menu
    
    @ViewBuilder
    private func ToolsOptionsMenu(topic: Topic) -> some View {
        Menu {
            ContextButton(
                text: topic.isHidden
                ? LocalizedStringResource("Remove Hide", bundle: .module)
                : LocalizedStringResource("Hide", bundle: .module),
                symbol: topic.isHidden ? .eyeSlashFill : .eyeSlash
            ) {
                send(.contextToolsMenu(.modify(.hide, !topic.isHidden)))
            }
            
            ContextButton(
                text: topic.isClosed
                ? LocalizedStringResource("Open Topic", bundle: .module)
                : LocalizedStringResource("Close Topic", bundle: .module),
                symbol: topic.isClosed ? .lockFill : .lock
            ) {
                send(.contextToolsMenu(.modify(.close, !topic.isClosed)))
            }
            
            if topic.canDelete {
                ContextButton(text: LocalizedStringResource("Delete Topic", bundle: .module), symbol: .trash) {
                    send(.contextToolsMenu(.modify(.delete, false)))
                }
            }
            
            ContextButton(
                text: LocalizedStringResource("Move", bundle: .module),
                symbol: .arrowRight
            ) {
                send(.contextToolsMenu(.move))
            }
        } label: {
            HStack {
                Text("Tools", bundle: .module)
                Image(systemSymbol: .shield)
            }
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
    
    // MARK: - Navigation
    
    @ViewBuilder
    private func Navigation() -> some View {
        if store.pageNavigation.shouldShow {
            PageNavigation(store: store.scope(state: \.pageNavigation, action: \.pageNavigation))
                .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private func Header() -> some View {
        HStack {
            if isPollAvailable, store.shouldShowTopicPollButton {
                Button {
                    send(.topicPollOpenButtonTapped)
                } label: {
                    Text("Poll", bundle: .module)
                        .font(.headline)
                        .bold()
                }
            }
            
            if store.shouldShowTopicHatButton {
                Button {
                    send(.topicHatOpenButtonTapped)
                } label: {
                    Text("Topic Hat", bundle: .module)
                        .font(.headline)
                        .bold()
                }
            }
        }
    }
    
    // MARK: - Poll
    
    @ViewBuilder
    private func Poll(_ poll: Topic.Poll) -> some View {
        VStack(spacing: 0) {
            if !store.shouldShowTopicPollButton {
                if store.shouldShowTopicHatButton {
                    PostSeparator()
                }
                
                PollView(poll: poll, onVoteButtonTapped: { selections in
                    send(.topicPollVoteButtonTapped(selections))
                })
                .padding(.top, store.shouldShowTopicHatButton ? 16 : 0)
            }
            
            PostSeparator()
        }
    }
    
    // MARK: - Post List
    
    @ViewBuilder
    private func PostList() -> some View {
        ForEach(store.posts) { post in
            WithPerceptionTracking {
                if store.shouldShowTopicHatButton && store.posts.first == post {
                    if !isPollAvailable {
                        PostSeparator()
                    }
                } else {
                    VStack(spacing: 0) {
                        Post(post)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        
                        PostSeparator()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func PostSeparator() -> some View {
        Rectangle()
            .foregroundStyle(Color(.Separator.post))
            .frame(height: 10)
    }
    
    // MARK: - Post
    
    @ViewBuilder
    private func Post(_ post: UIPost) -> some View {
        PostRowView(
            state: PostRowView.State(
                post: post,
                sessionUserId: store.isUserAuthorized ? store.userSession!.userId : 0,
                canPostInTopic: store.topic?.canPost ?? false,
                isUserAuthorized: store.isUserAuthorized,
                isContextMenuAvailable: true
            ),
            action: { action in
                switch action {
                case .userTapped:
                    send(.userTapped(post.post.author.id))
                case .urlTapped(let url):
                    send(.urlTapped(url))
                case .imageTapped(let url):
                    send(.imageTapped(url))
                case .textQuoted(let text):
                    send(.textQuoted(post, text))
                case .karmaHistoryTapped:
                    send(.karmaHistoryTapped(post.id))
                }
            },
            menuAction: { action in
                switch action {
                case .reply(let id, let authorName):
                    send(.contextPostMenu(.reply(id, authorName)))
                case .edit(let post):
                    send(.contextPostMenu(.edit(post)))
                case .karma(let postId):
                    send(.contextPostMenu(.karma(postId)))
                case .report(let postId):
                    send(.contextPostMenu(.report(postId)))
                case .changeReputation(let postId, let userId, let username):
                    send(.contextPostMenu(.changeReputation(postId, userId, username)))
                case .userPostsInTopic(let authorId):
                    send(.contextPostMenu(.userPostsInTopic(authorId)))
                case .mentions(let postId):
                    send(.contextPostMenu(.mentions(postId)))
                case .copyLink(let postId):
                    send(.contextPostMenu(.copyLink(postId)))
                }
            },
            toolsMenuAction: { action in
                switch action {
                case .move(let postId):
                    send(.contextPostToolsMenu(.move(postId)))
                case .modify(let action, let postId, let isUndo):
                    send(.contextPostToolsMenu(.modify(action, postId, isUndo)))
                }
            }
        )
        .listRowBackground(Color.clear)
        .listRowSeparator(Visibility.hidden)
        .scaleEffect(store.postId == post.id ? scrollScale : 1)
        .id(post.id)
    }
    
    // MARK: - Helpers
    
    private func scrollAndAnimate() async {
        guard let postId = store.postId, !store.isLoadingTopic else { return }
        
        withAnimation { scrollProxy?.scrollTo(postId, anchor: .top) }
        
        Task {
            // Wait for scroll animation
            try? await Task.sleep(for: .seconds(0.5))
            
            let duration = 0.25
            let animation = Animation.easeInOut(duration: duration)
            withAnimation(animation) { scrollScale = 0.95 }
            
            Task {
                try? await Task.sleep(for: .seconds(duration))
                withAnimation(animation) { scrollScale = 1 }
                try? await Task.sleep(for: .seconds(duration))
                send(.finishedPostAnimation, animation: .default)
            }
        }
    }
}

// MARK: - Navigation Modifier

struct NavigationModifier: ViewModifier {
    
    @Perception.Bindable private var store: StoreOf<TopicFeature>
    @Environment(\.tintColor) private var tintColor
    
    private var title: String {
        return store.topic?.name ?? store.topicName ?? String(localized: "Loading...", bundle: .module)
    }
    
    init(store: StoreOf<TopicFeature>) {
        self.store = store
    }
    
    func body(content: Content) -> some View {
        WithPerceptionTracking {
            content
                .navigationTitle(Text(title))
                ._toolbarTitleDisplayMode(.inline)
                .alert($store.scope(state: \.$destination, action: \.destination).alert)
                .modifier(FullScreenCoverModifier(store: store))
                .modifier(SheetModifier(store: store))
                .confirmationDialog(item: $store.destination.karmaChange, title: { _ in Text(verbatim: "") }) { postId in
                    Button {
                        store.send(.view(.changeKarmaTapped(postId, true)))
                    } label: {
                        Text("Up", bundle: .module)
                    }
                    
                    Button {
                        store.send(.view(.changeKarmaTapped(postId, false)))
                    } label: {
                        Text("Down", bundle: .module)
                    }
                }
        }
    }
    
    struct FullScreenCoverModifier: ViewModifier {
        @Perception.Bindable private var store: StoreOf<TopicFeature>
        @Environment(\.tintColor) private var tintColor
        
        init(store: StoreOf<TopicFeature>) {
            self.store = store
        }
        
        func body(content: Content) -> some View {
            WithPerceptionTracking {
                content
                    .fullScreenCover(item: $store.scope(state: \.$destination, action: \.destination).form) { store in
                        NavigationStack {
                            FormScreen(store: store)
                        }
                    }
                    .fullScreenCover(item: $store.scope(state: \.$destination, action: \.destination).gallery) { model in
                        TabViewGallery(model: model)
                    }
            }
        }
    }
    
    struct SheetModifier: ViewModifier {
        @Perception.Bindable private var store: StoreOf<TopicFeature>
        @Environment(\.tintColor) private var tintColor
        
        init(store: StoreOf<TopicFeature>) {
            self.store = store
        }
        
        func body(content: Content) -> some View {
            WithPerceptionTracking {
                Sheets(content: content)
            }
        }
        
        // Fix for compiler struggling with 4 sheets (works without WithPerceptionTracking)
        private func Sheets(content: Content) -> some View {
            content
                .fittedSheet(
                    item: $store.scope(state: \.$destination, action: \.destination).changeReputation,
                    embedIntoNavStack: true
                ) { store in
                    ReputationChangeView(store: store)
                }
                .fittedSheet(
                    item: $store.scope(state: \.$destination, action: \.destination).move,
                    embedIntoNavStack: true
                ) { store in
                    ForumMoveView(store: store)
                }
                .sheet(item: $store.scope(state: \.$destination, action: \.destination).karmaHistory) { store in
                    NavigationStack {
                        PostKarmaHistoryView(store: store)
                    }
                }
                .sheet(item: $store.scope(state: \.$destination, action: \.destination).stat) { store in
                    NavigationStack {
                        ForumStatView(store: store)
                    }
                }
        }
    }
}

extension View {
    func navigations(store: StoreOf<TopicFeature>) -> some View {
        self.modifier(NavigationModifier(store: store))
    }
}

// MARK: - Extensions

// TODO: Move to extensions?
extension Date {
    func formattedDate() -> LocalizedStringKey {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if Calendar.current.isDateInToday(self) {
            return LocalizedStringKey("Today, \(formatter.string(from: self))")
        } else if Calendar.current.isDateInYesterday(self) {
            return LocalizedStringKey("Yesterday, \(formatter.string(from: self))")
        } else {
            formatter.dateFormat = "dd.MM.yy, HH:mm"
            return LocalizedStringKey(formatter.string(from: self))
        }
    }
}

private extension TopicPostsFilter {
    var title: LocalizedStringKey {
        switch self {
        case .all:
            LocalizedStringKey("All")
        case .onlyHidden:
            LocalizedStringKey("Only hidden")
        case .onlyDefault:
            LocalizedStringKey("Only default")
        case .onlyDeleted:
            LocalizedStringKey("Only deleted")
        case .exceptDeleted:
            LocalizedStringKey("Except deleted")
        }
    }
}

// MARK: - Previews

#Preview {
    @Shared(.userSession) var userSession = UserSession.mock
    
    ScreenWrapper(hasBackButton: true) {
        TopicScreen(
            store: Store(
                initialState: TopicFeature.State(topicId: 0, topicName: "Test Topic")
            ) {
                TopicFeature()
            } withDependencies: {
                $0.apiClient.getTopic = { @Sendable _, _, _, _ in
                    return .mock
                }
            }
        )
    }
    .tint(Color(.Theme.primary))
    .environment(\.locale, Locale(identifier: "en"))
}

#Preview("New post requests attach") {
    @Shared(.userSession) var userSession = UserSession.mock
    postSendingPreview
}

@MainActor private var postSendingPreview: some View {
    TopicScreen(
        store: Store(
            initialState: TopicFeature.State(
                topicId: 0,
                topicName: "Test Topic",
                destination: .form(
                    FormFeature.State(
                        type: .post(
                            type: .new, topicId: 0, content: .simple("Test Text", [])
                        )
                    )
                )
            )
        ) {
            TopicFeature()
        } withDependencies: {
            $0.apiClient.sendPost = { request in
                try await Task.sleep(for: .seconds(1))
                if request.flag == 0 {
                    return .failure(.attach)
                } else {
                    return .success(.init(id: 0, topicId: 0, offset: 0))
                }
            }
        }
    )
    .tint(Color(.Theme.primary))
}

#Preview("Post sending returns error status") {
    @Shared(.userSession) var userSession = UserSession.mock
    postErrorStatusPreview
}

@MainActor private var postErrorStatusPreview: some View {
    TopicScreen(
        store: Store(
            initialState: TopicFeature.State(
                topicId: 0,
                topicName: "Test Topic",
                destination: .form(
                    FormFeature.State(
                        type: .post(
                            type: .new, topicId: 0, content: .simple("Test Text", [])
                        )
                    )
                )
            )
        ) {
            TopicFeature()
        } withDependencies: {
            $0.apiClient.sendPost = { request in
                try await Task.sleep(for: .seconds(1))
                return .failure(.tooLong) // <----------
            }
        }
    )
    .tint(Color(.Theme.primary))
}

#Preview("New template post requests") {
    @Shared(.userSession) var userSession = UserSession.mock
    templatePostSendingPreview
}

@MainActor private var templatePostSendingPreview: some View {
    TopicScreen(
        store: Store(
            initialState: TopicFeature.State(
                topicId: 0,
                topicName: "Test Topic",
                destination: .form(
                    FormFeature.State(
                        type: .post(
                            type: .new, topicId: 0, content: .template([])
                        )
                    )
                )
            )
        ) {
            TopicFeature()
        } withDependencies: {
            $0.apiClient.sendTemplate = { _, _, _ in
                try await Task.sleep(for: .seconds(1))
                return .success(.post(.init(id: 1, topicId: 0, offset: 0)))
            }
        }
    )
    .tint(Color(.Theme.primary))
}

#Preview("Post Template sending returns error status") {
    @Shared(.userSession) var userSession = UserSession.mock
    postTemplateErrorStatusPreview
}

@MainActor private var postTemplateErrorStatusPreview: some View {
    TopicScreen(
        store: Store(
            initialState: TopicFeature.State(
                topicId: 0,
                topicName: "Test Topic",
                destination: .form(
                    FormFeature.State(
                        type: .post(type: .new, topicId: 0, content: .template([]))
                    )
                )
            )
        ) {
            TopicFeature()
        } withDependencies: {
            $0.apiClient.sendTemplate = { _, _, _ in
                try await Task.sleep(for: .seconds(1))
                return .failure(.badParam) // <----------
            }
        }
    )
    .tint(Color(.Theme.primary))
}
