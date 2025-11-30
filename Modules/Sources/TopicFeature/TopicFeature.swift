//
//  ForumPageFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 07.11.2024.
//

import Foundation
import ComposableArchitecture
import PageNavigationFeature
import APIClient
import DeeplinkHandler
import Models
import SharedUI
import PersistenceKeys
import ParsingClient
import PasteboardClient
import WriteFormFeature
import ReputationChangeFeature
import TCAExtensions
import AnalyticsClient
import TopicBuilder
import ToastClient
import NotificationsClient
import SearchFeature

@Reducer
public struct TopicFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - Localizations
    
    private enum Localization {
        static let linkCopied = LocalizedStringResource("Link copied", bundle: .module)
        static let favoriteAdded = LocalizedStringResource("Added to favorites", bundle: .module)
        static let favoriteRemoved = LocalizedStringResource("Removed from favorites", bundle: .module)
        static let postDeleted = LocalizedStringResource("Post deleted", bundle: .module)
        static let postKarmaChanged = LocalizedStringResource("Post karma changed", bundle: .module)
        static let topicVoteApproved = LocalizedStringResource("Vote approved", bundle: .module)
    }
    
    // MARK: - Destinations
    
    @Reducer(state: .equatable)
    public enum Destination {
        @ReducerCaseIgnored
        case gallery([URL], [Int], Int)
        @ReducerCaseIgnored
        case karmaChange(Int)
        case editWarning
        case search(SearchFeature)
        case writeForm(WriteFormFeature)
        case changeReputation(ReputationChangeFeature)
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Shared(.appSettings) var appSettings: AppSettings
        @Shared(.userSession) var userSession: UserSession?
        
        @Presents public var destination: Destination.State?

        public let topicId: Int
        public let topicName: String?
        public let initialOffset: Int
        /// For animation purposes only
        var postId: Int?
        public var topic: Topic?
        public var goTo: GoTo
        
        var posts: [UIPost] = []
        
        var isLoadingTopic = true
        var isRefreshing = false
        
        public var pageNavigation = PageNavigationFeature.State(type: .topic)
        var floatingNavigation: Bool
        
        var didLoadOnce = false
        
        public var isUserAuthorized: Bool {
            return userSession != nil
        }
        
        var shouldShowTopicHatButton = false
        var shouldShowTopicPollButton = true
        
        public init(
            topicId: Int,
            topicName: String? = nil,
            initialOffset: Int = 0, // TODO: Not needed anymore?
            goTo: GoTo = .first,
            destination: Destination.State? = nil
        ) {
            self.topicId = topicId
            self.topicName = topicName
            self.goTo = goTo
            self.destination = destination
            self.floatingNavigation = _appSettings.floatingNavigation.wrappedValue
            
            // If we open this screen with Go To End usage then we can get offset like 99
            // which means that we need to lower it to 80 (if topicPerPage is 20) with remainder
            // so we can get full page of posts instead only last one post
            self.initialOffset = initialOffset - (initialOffset % _appSettings.topicPerPage.wrappedValue)
//            self.initialOffset = _appSettings.topicPerPage.wrappedValue * (targetPage - 1)
        }
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction, BindableAction {
        case binding(BindingAction<State>)
        case destination(PresentationAction<Destination.Action>)
        case pageNavigation(PageNavigationFeature.Action)

        case view(View)
        public enum View {
            case onFirstAppear
            case onNextAppear
            case onRefresh
            case finishedPostAnimation
            case topicHatOpenButtonTapped
            case topicPollOpenButtonTapped
            case topicPollVoteButtonTapped([Int: Set<Int>])
            case changeKarmaTapped(Int, Bool)
            case searchButtonTapped
            case userTapped(Int)
            case urlTapped(URL)
            case imageTapped(URL)
            case contextMenu(TopicContextMenuAction)
            case contextPostMenu(PostMenuAction)
            case editWarningSheetCloseButtonTapped
        }
        
        case `internal`(Internal)
        public enum Internal {
            case load
            case refresh
            case goToPost(postId: Int, offset: Int, forceRefresh: Bool)
            case changeKarma(postId: Int, isUp: Bool)
            case voteInPoll(selections: [[Int]])
            case loadTopic(Int)
            case loadTypes([[UITopicType]])
            case topicResponse(Result<Topic, any Error>)
            case setFavoriteResponse(Bool)
            case jumpRequestFailed
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case handleUrl(URL)
            case openUser(id: Int)
            case openSearch(SearchResult)
            case openedLastPage
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.logger) var logger
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.continuousClock) private var clock
    @Dependency(\.cacheClient) private var cacheClient
    @Dependency(\.toastClient) private var toastClient
    @Dependency(\.analyticsClient) private var analyticsClient
    @Dependency(\.pasteboardClient) private var pasteboardClient
    @Dependency(\.notificationCenter) private var notificationCenter
    @Dependency(\.notificationsClient) private var notificationsClient
    
    // MARK: - Cancellable
    
    private enum CancelID { case loading }
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Scope(state: \.pageNavigation, action: \.pageNavigation) {
            PageNavigationFeature()
        }
        
        Reduce<State, Action> { state, action in
            switch action {
            case let .pageNavigation(.offsetChanged(to: newOffset)):
                state.isRefreshing = false
                state.postId = nil
                state.posts.removeAll()
                return .concatenate([
                    .run { [isLastPage = state.pageNavigation.isLastPage, topicId = state.topicId] _ in
                        if isLastPage {
                            await cacheClient.deleteTopicIdOfUnreadItem(topicId)
                        }
                    },
                    .cancel(id: CancelID.loading),
                    .send(.internal(.loadTopic(newOffset)))
                ])
                
            case let .destination(.presented(.writeForm(.delegate(.writeFormSent(response))))):
                if case let .post(data) = response,
                   case let .success(post) = data {
                    return jumpTo(.post(id: post.id), true, &state)
                }
                return .none
                
            case let .destination(.presented(.search(.delegate(.userProfileTapped(id))))):
                return .send(.delegate(.openUser(id: id)))
                
            case let .destination(.presented(.search(.delegate(.searchOptionsConstructed(options))))):
                return .send(.delegate(.openSearch(options)))
                
            case .destination, .pageNavigation, .binding:
                return .none
                
            case .view(.onFirstAppear):
                return .merge(
                    .run { [topicId = state.topicId] send in
                        for await notification in notificationsClient.eventPublisher().values {
                            if case let .topic(eventId) = notification, eventId == topicId {
                                await send(.internal(.refresh))
                            }
                        }
                    },
                    .run { send in
                        for await _ in notificationCenter.notifications(named: .sceneBecomeActive) {
                            await send(.internal(.refresh))
                        }
                    },
                    .send(.internal(.load))
                )
                
            case .view(.onNextAppear):
                return .send(.internal(.refresh))
                
            case .view(.onRefresh):
                return .send(.internal(.refresh))
                
            case .view(.searchButtonTapped):
                let navigation: [ForumInfo] = if let topic = state.topic {
                    !topic.navigation.isEmpty ? [topic.navigation.first!] : []
                } else { [] }
                state.destination = .search(SearchFeature.State(
                    on: .topic(id: state.topicId),
                    navigation: navigation
                ))
                return .none
                
            case .view(.topicHatOpenButtonTapped):
                guard let firstPost = state.topic?.posts.first else { fatalError("No Topic Hat Found") }
                let firstPostNodes = TopicNodeBuilder(text: firstPost.content, attachments: firstPost.attachments).build()
                state.posts[0] = UIPost(post: firstPost, content: firstPostNodes.map { .init(value: $0) })
                state.shouldShowTopicHatButton = false
                return .none
                
            case .view(.topicPollOpenButtonTapped):
                state.shouldShowTopicPollButton = false
                return .none
                
            case let .view(.topicPollVoteButtonTapped(selections)):
                let values = selections.sorted(by: { $0.key < $1.key }).map {
                    Array($0.value)
                }
                return .send(.internal(.voteInPoll(selections: values)))
                
            case let .view(.userTapped(id)):
                return .send(.delegate(.openUser(id: id)))
                
            case let .view(.urlTapped(url)):
                return .send(.delegate(.handleUrl(url)))
                
            case let .view(.contextMenu(action)):
                guard let topic = state.topic else { return .none }
                switch action {
                case .writePost:
                    let feature = WriteFormFeature.State(
                        formFor: .post(
                            type: .new,
                            topicId: topic.id,
                            content: .simple("", [])
                        )
                    )
                    state.destination = .writeForm(feature)
                    return .none
                    
                case .openInBrowser:
                    let url = URL(string: "https://4pda.to/forum/index.php?showtopic=\(topic.id)")!
                    return .run { _ in await open(url: url) }
                    
                case .copyLink:
                    pasteboardClient.copy("https://4pda.to/forum/index.php?showtopic=\(topic.id)")
                    return .run { _ in
                        await toastClient.showToast(ToastMessage(text: Localization.linkCopied, haptic: .success))
                    }
                    
                case .setFavorite:
                    return .run { [id = state.topicId] send in
                        let request = SetFavoriteRequest(id: id, action: topic.isFavorite ? .delete : .add, type: .topic)
                        _ = try await apiClient.setFavorite(request)
                        await send(.internal(.setFavoriteResponse(!topic.isFavorite)))
                        
                        let text = topic.isFavorite ? Localization.favoriteRemoved : Localization.favoriteAdded
                        await toastClient.showToast(ToastMessage(text: text))
                    } catch: { error, send in
                        analyticsClient.capture(error)
                        await toastClient.showToast(.whoopsSomethingWentWrong)
                    }
                    
                case .goToEnd:
                    return .send(.pageNavigation(.lastPageTapped))
                }
                
            case let .view(.contextPostMenu(action)):
                switch action {
                case .reply(let postId, let authorName):
                    let feature = WriteFormFeature.State(
                        formFor: .post(
                            type: .new,
                            topicId: state.topicId,
                            content: .simple("[SNAPBACK]\(postId)[/SNAPBACK] [B]\(authorName)[/B], ", [])
                        )
                    )
                    state.destination = .writeForm(feature)
                    return .none
                    
                case .edit(let post):
                    let feature = WriteFormFeature.State(
                        formFor: .post(
                            type: .edit(postId: post.id),
                            topicId: state.topicId,
                            content: .simple(post.content, post.attachments.map { $0.id })
                        )
                    )
                    if post.attachments.isEmpty {
                        state.destination = .writeForm(feature)
                    } else {
                        state.destination = .editWarning
                    }
                    return .none
                    
                case .report(let id):
                    let feature = WriteFormFeature.State(
                        formFor: .report(id: id, type: .post)
                    )
                    state.destination = .writeForm(feature)
                    return .none
                    
                case .delete(let id):
                    return .concatenate(
                        .run { _ in
                            let status = try await apiClient.deletePosts(postIds: [id])
                            let postDeletedToast = ToastMessage(text: Localization.postDeleted, haptic: .success)
                            await toastClient.showToast(status ? postDeletedToast : .whoopsSomethingWentWrong)
                        }.cancellable(id: CancelID.loading),
                        
                        jumpTo(.post(id: id), true, &state)
                    )
                    
                case .karma(let id):
                    state.destination = .karmaChange(id)
                    return .none

                case .changeReputation(let postId, let userId, let username):
                    let feature = ReputationChangeFeature.State(
                        userId: userId,
                        username: username,
                        content: .post(id: postId)
                    )
                    state.destination = .changeReputation(feature)
                    return .none
                    
                case .copyLink(let postId):
                    let link = "https://4pda.to/forum/index.php?showtopic=\(state.topicId)&view=findpost&p=\(postId)"
                    pasteboardClient.copy(link)
                    return .run { _ in
                        await toastClient.showToast(ToastMessage(text: Localization.linkCopied, haptic: .success))
                    }
                }
                
            case .view(.changeKarmaTapped(let postId, let isUp)):
                return .send(.internal(.changeKarma(postId: postId, isUp: isUp)))
                
            case let .view(.imageTapped(url)):
                guard let topic = state.topic else { fatalError() }
                for post in topic.posts {
                    for attachment in post.attachments {
                        guard attachment.type == .image else { continue }
                        guard attachment.size != 0 else { continue } // Don't show inline images
                        if let attachmentUrl = attachment.metadata?.url {
                            if attachmentUrl == url {
                                let urls = post.imageAttachmentsOrdered.map { $0.metadata!.url }
                                let ids = post.imageAttachmentsOrdered.map { $0.id }
                                let index = ids.firstIndex(of: attachment.id) ?? 0
                                state.destination = .gallery(urls, ids, index)
                                break
                            }
                        }
                    }
                }
                return .none
                
            case .view(.finishedPostAnimation):
                state.postId = nil
                return .none.animation()
                
            case .view(.editWarningSheetCloseButtonTapped):
                state.destination = nil
                return .none
                
            case .internal(.load):
                switch state.goTo {
                case .first:            return loadPage(&state)
                case .unread:           return jumpTo(.unread, false, &state)
                case .post(id: let id): return jumpTo(.post(id: id), false, &state)
                case .page(let page):   return jumpTo(.page(page), false, &state)
                case .last:             return jumpTo(.last, false, &state)
                }
                
            case .internal(.refresh):
                state.isRefreshing = true
                return .run { [offset = state.pageNavigation.offset] send in
                    await send(.internal(.loadTopic(offset)))
                }
                
            case .internal(.changeKarma(let postId, let isUp)):
                return .concatenate(
                    .run { _ in
                        let status = try await apiClient.postKarma(postId: postId, isUp: isUp)
                        let postKarmaChangedToast = ToastMessage(text: Localization.postKarmaChanged, haptic: .success)
                        await toastClient.showToast(status ? postKarmaChangedToast : .whoopsSomethingWentWrong)
                    }.cancellable(id: CancelID.loading),
                
                    jumpTo(.post(id: postId), true, &state)
                )
                
            case let .internal(.voteInPoll(selections)):
                return .concatenate(
                    .run { [topicId = state.topicId] _ in
                        let status = try await apiClient.voteInTopicPoll(
                            topicId: topicId,
                            selections: selections
                        )
                        let voteApproved = ToastMessage(text: Localization.topicVoteApproved, haptic: .success)
                        await toastClient.showToast(status ? voteApproved : .whoopsSomethingWentWrong)
                    }.cancellable(id: CancelID.loading),
                    
                    .send(.internal(.refresh))
                )
                
            case let .internal(.loadTopic(offset)):
                if !state.isRefreshing {
                    state.isLoadingTopic = true
                }
                return .run { [id = state.topicId, perPage = state.appSettings.topicPerPage, isRefreshing = state.isRefreshing] send in
                    let startTime = Date()
                    let topic = try await apiClient.getTopic(id, offset, perPage)
                    if isRefreshing { await delayUntilTimePassed(1.0, since: startTime) }
                    await send(.internal(.topicResponse(.success(topic))))
                } catch: { error, send in
                    await send(.internal(.topicResponse(.failure(error))))
                }
                .cancellable(id: CancelID.loading)
                
            case let .internal(.topicResponse(.success(topic))):
                //customDump(topic)
                state.topic = topic

                return .concatenate(
                    updatePageNavigation(&state),
                    
                    .run { [
                        isFirstPage = state.pageNavigation.isFirstPage,
                        topicPerPage = state.appSettings.topicPerPage,
                        shouldShowTopicHatButton = state.shouldShowTopicHatButton
                    ] send in
                        var topicTypes: [[UITopicType]] = []
                        
                        topicTypes = await withTaskGroup(of: (Int, [UITopicType]).self, returning: [[UITopicType]].self) { taskGroup in
                            for (index, post) in topic.posts.enumerated() {
                                // guard index == 0 else { continue } // For test purposes
                                var text = post.content
                                // print(post)
                                if index == 0 && !isFirstPage && shouldShowTopicHatButton {
                                    text = "" // Not loading hat post for non-first page
                                }
                                taskGroup.addTask {
                                    return (index, TopicNodeBuilder(text: text, attachments: post.attachments).build())
                                }
                            }
                            
                            var types = Array<[UITopicType]?>(repeating: nil, count: topicPerPage + 1)
                            for await (index, result) in taskGroup {
                                types[index] = result
                            }
                            return types.map { $0 ?? [] }
                        }
                        await send(.internal(.loadTypes(topicTypes)))
                    }.cancellable(id: CancelID.loading),
                    
                    .run { [isLastPage = state.pageNavigation.isLastPage] send in
                        if isLastPage {
                            notificationCenter.post(name: .favoritesUpdated, object: nil)
                        }
                    }
                )
                
            case let .internal(.loadTypes(types)):
                if state.posts.isEmpty {
                    state.posts = zip(state.topic!.posts, types).map { post, types in
                        return UIPost(post: post, content: types.map { .init(value: $0) })
                    }
                } else {
                    state.posts = mergeUIPosts(old: state.posts, newPosts: state.topic!.posts, newTypes: types)
                }
                
                state.isLoadingTopic = false
                state.isRefreshing = false
                state.shouldShowTopicPollButton = true
                state.shouldShowTopicHatButton = !state.pageNavigation.isFirstPage
                
                reportFullyDisplayed(&state)
                return .none
                
            case .internal(.topicResponse(.failure)):
                state.isRefreshing = false
                reportFullyDisplayed(&state)
                return .run { _ in
                    await toastClient.showToast(.whoopsSomethingWentWrong)
                }
                
            case let .internal(.setFavoriteResponse(isFavorite)):
                state.topic?.isFavorite = isFavorite
                notificationCenter.post(name: .favoritesUpdated, object: nil)
                return .none
                
            case .internal(.jumpRequestFailed):
                return .run { _ in
                    await toastClient.showToast(.whoopsSomethingWentWrong)
                }
                
            case let .internal(.goToPost(postId: postId, offset: offset, forceRefresh)):
                state.postId = postId
                if !forceRefresh && offset == state.pageNavigation.offset && state.topic != nil {
                    // If we have this post on the same page without force refresh, don't reload
                    return .none
                }
                return loadPage(offset: offset, &state)
                
            case .delegate:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        
        Analytics()
    }
    
    // MARK: - Shared Logic
    
    /// If offset is set to nil, then initialOffset property will be used
    private func loadPage(offset: Int? = nil, _ state: inout State) -> Effect<Action> {
        return .concatenate(
            updatePageNavigation(&state, offset: offset ?? state.initialOffset),
            .cancel(id: CancelID.loading),
            .send(.internal(.loadTopic(offset ?? state.initialOffset)))
        )
    }
    
    private func mergeUIPosts(old: [UIPost], newPosts: [Post], newTypes: [[UITopicType]]) -> [UIPost] {
        zip(newPosts, newTypes).map { newPost, newTypes in
            if let oldPost = old.first(where: { $0.id == newPost.id }) {
                let mergedContent = mergePostContent(
                    old: oldPost.content,
                    new: newTypes
                )
                return UIPost(post: newPost, content: mergedContent)
            } else {
                return UIPost(post: newPost, content: newTypes.map { .init(value: $0) })
            }
        }
    }
    
    private func mergePostContent(old: [UIPost.Content], new: [UITopicType]) -> [UIPost.Content] {
        new.map { newType in
            if let match = old.first(where: { $0.value.hashValue == newType.hashValue }) {
                return match
            } else {
                return UIPost.Content(value: newType)
            }
        }
    }
    
    #warning("move")
    public enum JumpTo: Sendable {
        case unread
        case last
        case post(id: Int)
        case page(Int)
        
        var postId: Int {
            switch self {
            case .unread, .last: return 0
            case let .post(id):  return id
            case .page: fatalError("Unsupported interaction")
            }
        }
        
        var type: JumpForumRequest.ForumJumpType {
            switch self {
            case .unread: return .new
            case .last:   return .last
            case .post:   return .post
            case .page:   fatalError("Unsupported interaction")
            }
        }
    }
    
    public func jumpTo(_ jump: JumpTo, _ forceRefresh: Bool, _ state: inout State) -> Effect<Action> {
        if case let .page(page) = jump {
            return reduce(into: &state, action: .pageNavigation(.goToPage(newPage: page)))
        }
        
        return .run { [topicId = state.topicId, topicPerPage = state.appSettings.topicPerPage] send in
            let request = JumpForumRequest(postId: jump.postId, topicId: topicId, allPosts: true, type: jump.type)
            let response = try await apiClient.jumpForum(request)
            let offset = response.offset - (response.offset % topicPerPage)
            await send(.internal(.goToPost(postId: response.postId, offset: offset, forceRefresh: forceRefresh)))
        } catch: { error, send in
            await send(.internal(.jumpRequestFailed))
        }
    }
    
    private func updatePageNavigation(_ state: inout TopicFeature.State, offset: Int? = nil) -> Effect<Action> {
        return PageNavigationFeature()
            .reduce(
                into: &state.pageNavigation,
                action: .update(
                    count: state.topic?.postsCount ?? 0,
                    offset: offset
                )
            )
            .map(Action.pageNavigation)
    }
    
    private func reportFullyDisplayed(_ state: inout State) {
        guard !state.didLoadOnce else { return }
        analyticsClient.reportFullyDisplayed()
        state.didLoadOnce = true
    }
}

func measureElapsedTime(_ operation: () throws -> Void) throws -> UInt64 {
    let startTime = DispatchTime.now()
    try operation()
    let endTime = DispatchTime.now()

    let elapsedTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
    let elapsedTimeInMilliSeconds = Double(elapsedTime) / 1_000_000.0

    return UInt64(elapsedTimeInMilliSeconds)
}

func measureAverageTime(timesToRun: Int, _ operation: () throws -> Void) throws {
    var times = [UInt64]()
    for _ in 0..<timesToRun {
        let time = try measureElapsedTime(operation)
        times.append(time)
    }
    let time = times.reduce(0, +) / UInt64(times.count)
    print("Average time after \(timesToRun) runs: \(time) ms")
}
