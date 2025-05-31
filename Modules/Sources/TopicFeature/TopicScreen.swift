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
import TopicBuilder
import GalleryFeature

public struct TopicScreen: View {
    
    @Perception.Bindable public var store: StoreOf<TopicFeature>
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.tintColor) private var tintColor
    @State private var scrollProxy: ScrollViewProxy?
    @State private var scrollScale: CGFloat = 1
    
    public init(store: StoreOf<TopicFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                if let topic = store.topic {
                    ScrollViewReader { proxy in
                        WithPerceptionTracking {
                            ScrollView {
                                LazyVStack(spacing: 16) {
                                    Navigation()
                                    
                                    if !store.isLoadingTopic {
                                        PostList(topic: topic)
                                        
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
            }
            .refreshable {
                // Wrapper around finish() due to SwiftUI bug
                await Task { await store.send(.onRefresh).finish() }.value
            }
            .overlay {
                if store.topic == nil || store.isLoadingTopic {
                    PDALoader()
                        .frame(width: 24, height: 24)
                }
            }
            .navigationTitle(Text(store.topic?.name ?? store.topicName ?? String(localized: "Loading...", bundle: .module)))
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(item: $store.scope(state: \.destination?.writeForm, action: \.destination.writeForm)) { store in
                NavigationStack {
                    WriteFormScreen(store: store)
                }
            }
            .fullScreenCover(item: $store.scope(state: \.destination?.gallery, action: \.destination.gallery)) { store in
                let state = store.withState { $0 }
                TabViewGallery(gallery: state.0, ids: state.1, selectedImageID: state.2)
            }
            .toolbar { OptionsMenu() }
            .onChange(of: store.postId)         { _ in Task { await scrollAndAnimate() } }
            .onChange(of: store.isLoadingTopic) { _ in Task { await scrollAndAnimate() } }
            .onChange(of: scenePhase) { newScenePhase in
                if (scenePhase == .inactive || scenePhase == .background) && newScenePhase == .active {
                    store.send(.onSceneBecomeActive)
                }
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
            if let topic = store.topic, store.isUserAuthorized, topic.canPost {
                Section {
                    ContextButton(text: "Write Post", symbol: .plusCircle, bundle: .module) {
                        store.send(.contextMenu(.writePost))
                    }
                }
            }
            
            ContextButton(text: "Copy Link", symbol: .docOnDoc, bundle: .module) {
                store.send(.contextMenu(.copyLink))
            }
            ContextButton(text: "Open In Browser", symbol: .safari, bundle: .module) {
                store.send(.contextMenu(.openInBrowser))
            }
            
            if !store.pageNavigation.isLastPage {
                Section {
                    ContextButton(text: "Go To End", symbol: .chevronRight2, bundle: .module) {
                        store.send(.contextMenu(.goToEnd))
                    }
                }
            }
            
            if let topic = store.topic, store.isUserAuthorized {
                Section {
                    ContextButton(
                        text: topic.isFavorite ? "Remove from favorites" : "Add to favorites",
                        symbol: topic.isFavorite ? .starFill : .star,
                        bundle: .module
                    ) {
                        store.send(.contextMenu(.setFavorite))
                    }
                }
            }
        } label: {
            Image(systemSymbol: .ellipsisCircle)
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
    private func PostList(topic: Topic) -> some View {
        ForEach(topic.posts) { post in
            WithPerceptionTracking {
                VStack(spacing: 0) {
                    if !store.isFirstPage && topic.posts.first == post {
                        // TODO: Add expandable head topic
//                        Text("Шапка Темы")
//                            .padding(16)
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
    private func Post(_ post: Post) -> some View {
        VStack(spacing: 8) {
            PostHeader(post)
            PostBody(post)
            if let lastEdit = post.lastEdit {
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
            Button {
                store.send(.userAvatarTapped(post.author.id))
            } label: {
                LazyImage(url: URL(string: post.author.avatarUrl)) { state in
                    if let image = state.image {
                        image.resizable().scaledToFill()
                    } else {
                        Image(.avatarDefault).resizable().scaledToFill()
                    }
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            }
            
            VStack(spacing: 4) {
                HStack(spacing: 8) {
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
                    
                    Text(post.createdAt.formatted())
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
    private func PostBody(_ post: Post) -> some View {
        VStack(spacing: 8) {
            if let postIndex = store.topic?.posts.firstIndex(of: post) {
                if store.types.count - 1 >= postIndex {
                    ForEach(store.types[postIndex], id: \.self) { type in
                        TopicView(type: type, attachments: post.attachments) { url in
                            store.send(.urlTapped(url))
                        } onImageTap: { url in
                            store.send(.imageTapped(url))
                        }
                    }
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
                ContextButton(text: "Reply", symbol: .arrowTurnUpRight, bundle: .module) {
                    store.send(.contextPostMenu(.reply(post.id, post.author.name)))
                }
            }
            
            if post.canEdit {
                ContextButton(text: "Edit", symbol: .squareAndPencil, bundle: .module) {
                    store.send(.contextPostMenu(.edit(post)))
                }
            }
            
            if post.canDelete {
                ContextButton(text: "Delete", symbol: .trash, bundle: .module) {
                    store.send(.contextPostMenu(.delete(post.id)))
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
                store.send(.finishedPostAnimation)
            }
        }
    }
}

// MARK: - Previews

#Preview {
    @Shared(.userSession) var userSession = UserSession(userId: 0, token: "", isHidden: false)
    
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
    .tint(Color(.Theme.primary))
}
