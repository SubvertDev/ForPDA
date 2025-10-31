//
//  ForumPageScreen.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 07.11.2024.
//

import SwiftUI
import ComposableArchitecture
import PageNavigationFeature
import WriteFormFeature
import SFSafeSymbols
import SharedUI
import NukeUI
import Models
import ParsingClient
import ReputationChangeFeature
import TopicBuilder
import GalleryFeature

@ViewAction(for: TopicFeature.self)
public struct TopicScreen: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<TopicFeature>
    
    @Environment(\.tintColor) private var tintColor
    @State private var scrollProxy: ScrollViewProxy?
    @State private var scrollScale: CGFloat = 1
    @State private var showKarmaConfirmation = false
    
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
                                    PostList()
                                }
                                
                                if shouldShowBottomNavigation {
                                    Navigation()
                                }
                            }
                            .padding(.bottom, 16)
                        }
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
            .toolbar { OptionsMenu() }
            ._safeAreaBar(edge: .bottom) {
                if isLiquidGlass,
                   store.appSettings.floatingNavigation,
                   !store.appSettings.experimentalFloatingNavigation{
                    Navigation()
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
                }
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
    
    // MARK: - Navigation
    
    @ViewBuilder
    private func Navigation() -> some View {
        if store.pageNavigation.shouldShow {
            PageNavigation(store: store.scope(state: \.pageNavigation, action: \.pageNavigation))
                .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Post List
    
    @ViewBuilder
    private func PostList() -> some View {
        ForEach(store.posts) { post in
            WithPerceptionTracking {
                VStack(spacing: 0) {
                    if store.shouldShowTopicHatButton && store.posts.first == post {
                        Button {
                            send(.topicHatOpenButtonTapped)
                        } label: {
                            Text("Topic Hat", bundle: .module)
                                .font(.headline)
                                .bold()
                                .padding(16)
                        }
                    } else {
                        Post(post)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                    }
                    
                    Rectangle()
                        .foregroundStyle(Color(.Separator.post))
                        .frame(height: 10)
                }
            }
        }
    }
    
    // MARK: - Post
    
    @ViewBuilder
    private func Post(_ post: UIPost) -> some View {
        VStack(spacing: 8) {
            PostHeader(post.post)
            PostBody(post)
            if let lastEdit = post.post.lastEdit {
                PostFooter(lastEdit)
            }
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .scaleEffect(store.postId == post.id ? scrollScale : 1)
        .id(post.id)
    }
    
    // MARK: - Post Header
    
    @ViewBuilder
    private func PostHeader(_ post: Post) -> some View {
        HStack(spacing: 8) {
            LazyImage(url: URL(string: post.author.avatarUrl)) { state in
                if let image = state.image {
                    image.resizable().scaledToFill()
                } else {
                    Image(.avatarDefault).resizable().scaledToFill()
                }
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
            .onTapGesture {
                send(.userTapped(post.author.id))
            }
            
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Group {
                        Text(post.author.name)
                            .font(.subheadline)
                            .bold()
                            .foregroundStyle(Color(.Labels.primary))
                            .lineLimit(1)
                        
                        Text(String(post.author.reputationCount))
                            .font(.caption)
                            .foregroundStyle(Color(.Labels.secondary))
                            .padding(.vertical, 4)
                            .padding(.horizontal, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .foregroundStyle(Color(.Background.teritary))
                            )
                    }
                    .onTapGesture {
                        send(.userTapped(post.author.id))
                    }
                    
                    Spacer()
                    
                    if post.karma != 0 {
                        Text(String(post.karma))
                            .font(.caption)
                            .foregroundStyle(Color(.Labels.primary))
                    }
                }
                
                HStack(spacing: 8) {
                    Text(User.Group(rawValue: post.author.groupId)!.title)
                        .font(.caption)
                        .foregroundStyle(Color(.Labels.teritary))
                    
                    Spacer()
                    
                    Text(post.createdAt.formattedDate(), bundle: .module)
                        .font(.caption)
                        .foregroundStyle(Color(.Labels.quaternary))
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            
            if store.isUserAuthorized, let topic = store.topic, topic.canPost {
                OptionsPostMenu(post)
            }
        }
    }
    
    // MARK: - Post Body
    
    @ViewBuilder
    private func PostBody(_ post: UIPost) -> some View {
        VStack(spacing: 8) {
            ForEach(post.content, id: \.self) { type in
                TopicView(type: type.value, attachments: post.post.attachments) { url in
                    send(.urlTapped(url))
                } onImageTap: { url in
                    send(.imageTapped(url))
                }
            }
        }
    }
    
    // MARK: - Post Footer
    
    @ViewBuilder
    private func PostFooter(_ lastEdit: Post.LastEdit) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Edited: \(lastEdit.username) • \(lastEdit.date.formatted())", bundle: .module)
            if !lastEdit.reason.isEmpty {
                Text("Reason: \(lastEdit.reason)", bundle: .module)
            }
        }
        .font(.caption2)
        .foregroundStyle(Color(.Labels.teritary))
        .padding(.top, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Options Post Menu
    
    @ViewBuilder
    private func OptionsPostMenu(_ post: Post) -> some View {
        Menu {
            Section {
                ContextButton(text: LocalizedStringResource("Reply", bundle: .module), symbol: .arrowTurnUpRight) {
                    send(.contextPostMenu(.reply(post.id, post.author.name)))
                }
            }
            
            if store.isUserAuthorized, store.userSession!.userId != post.author.id, post.canChangeKarma {
                ContextButton(text: LocalizedStringResource("Rate", bundle: .module), symbol: .chevronUpChevronDown) {
                    send(.contextPostMenu(.karma(post.id)))
                }
            }
            
            if post.canEdit {
                ContextButton(text: LocalizedStringResource("Edit", bundle: .module), symbol: .squareAndPencil) {
                    send(.contextPostMenu(.edit(post)))
                }
            }
            
            ContextButton(text: LocalizedStringResource("Report", bundle: .module), symbol: .exclamationmarkTriangle) {
                send(.contextPostMenu(.report(post.id)))
            }
            
            if post.canDelete {
                ContextButton(text: LocalizedStringResource("Delete", bundle: .module), symbol: .trash) {
                    send(.contextPostMenu(.delete(post.id)))
                }
            }
            
            if store.isUserAuthorized, post.author.id != store.userSession!.userId {
                Section {
                    ContextButton(text: LocalizedStringResource("Reputation", bundle: .module), symbol: .plusminus) {
                        send(.contextPostMenu(.changeReputation(post.id, post.author.id, post.author.name)))
                    }
                }
            }
            
            Section {
                ContextButton(text: LocalizedStringResource("Copy Link", bundle: .module), symbol: .docOnDoc) {
                    send(.contextPostMenu(.copyLink(post.id)))
                }
            }
        } label: {
            Image(systemSymbol: .ellipsis)
                .font(.body)
                .foregroundStyle(Color(.Labels.teritary))
                .padding(.horizontal, 8) // Padding for tap area
                .padding(.vertical, 16)
                .rotationEffect(.degrees(90))
        }
        .onTapGesture {} // DO NOT DELETE, FIX FOR IOS 17
        .frame(width: 8, height: 22)
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
                send(.finishedPostAnimation)
            }
        }
    }
}

// MARK: - Navigation Modifier

struct NavigationModifier: ViewModifier {
    
    @Perception.Bindable private var store: StoreOf<TopicFeature>
    @Environment(\.tintColor) private var tintColor
    
    init(store: StoreOf<TopicFeature>) {
        self.store = store
    }
    
    func body(content: Content) -> some View {
        WithPerceptionTracking {
            content
                .navigationTitle(Text(store.topic?.name ?? store.topicName ?? String(localized: "Loading...", bundle: .module)))
                ._toolbarTitleDisplayMode(.inline)
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
                    .fullScreenCover(item: $store.scope(state: \.destination?.writeForm, action: \.destination.writeForm)) { store in
                        NavigationStack {
                            WriteFormScreen(store: store)
                        }
                    }
                    .fullScreenCover(item: $store.scope(state: \.destination?.gallery, action: \.destination.gallery)) { store in
                        let state = store.withState { $0 }
                        TabViewGallery(gallery: state.0, ids: state.1, selectedImageID: state.2)
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
                content
                    .fittedSheet(
                        item: $store.scope(state: \.destination?.changeReputation, action: \.destination.changeReputation),
                        embedIntoNavStack: true
                    ) { store in
                        ReputationChangeView(store: store)
                    }
                    .sheet(isPresented: Binding($store.destination.editWarning)) {
                        EditWarningSheet()
                            .presentationDetents([.medium])
                            .presentationDragIndicator(.visible)
                    }
            }
        }
        
        // TODO: Move to SharedUI?
        // MARK: - Edit Warning Sheet
        
        @ViewBuilder
        private func EditWarningSheet() -> some View {
            VStack(spacing: 0) {
                Spacer()
                
                Image(systemSymbol: .hammer)
                    .font(.title)
                    .foregroundStyle(tintColor)
                    .padding(.bottom, 8)
                
                Text("Editing posts with attachments is not yet supported", bundle: .module)
                    .font(.title3)
                    .bold()
                    .foregroundStyle(Color(.Labels.primary))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 6)
                
                Spacer()
                
                Button {
                    store.send(.view(.editWarningSheetCloseButtonTapped))
                } label: {
                    Text("Understood", bundle: .module)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(tintColor)
                .frame(height: 48)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(ignoresSafeAreaEdges: .bottom)
            }
            .background {
                VStack(spacing: 0) {
                    ComingSoonTape()
                        .rotationEffect(Angle(degrees: 12))
                        .padding(.top, 32)
                    
                    Spacer()
                    
                    ComingSoonTape()
                        .rotationEffect(Angle(degrees: -12))
                        .padding(.bottom, 96)
                }
            }
            .frame(maxWidth: .infinity)
            .overlay(alignment: .topTrailing) {
                Button {
                    store.send(.view(.editWarningSheetCloseButtonTapped))
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(.Background.quaternary))
                            .frame(width: 30, height: 30)
                        
                        Image(systemSymbol: .xmark)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color(.Labels.teritary))
                    }
                    .padding(.top, 14)
                    .padding(.trailing, 16)
                }
            }
        }
        
        @ViewBuilder
        private func ComingSoonTape() -> some View {
            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { index in
                    Text("IN DEVELOPMENT", bundle: .module)
                        .font(.footnote)
                        .foregroundStyle(Color(.Labels.primaryInvariably))
                        .fixedSize(horizontal: true, vertical: false)
                        .lineLimit(1)
                }
            }
            .frame(width: UIScreen.main.bounds.width * 2, height: 26)
            .background(tintColor)
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
private extension Date {
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
                $0.apiClient.getTopic = { @Sendable _, _, _ in
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
                destination: .writeForm(
                    WriteFormFeature.State(
                        formFor: .post(
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
                destination: .writeForm(
                    WriteFormFeature.State(
                        formFor: .post(
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
