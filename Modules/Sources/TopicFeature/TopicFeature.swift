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
import PersistenceKeys
import ParsingClient
import PasteboardClient
import NotificationCenterClient
import WriteFormFeature
import TCAExtensions
import AnalyticsClient
import TopicBuilder
import ToastClient

@Reducer
public struct TopicFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - Destinations
    
    @Reducer(state: .equatable)
    public enum Destination {
        @ReducerCaseIgnored
        case gallery([URL], [Int], Int)
        case editWarning
        case writeForm(WriteFormFeature)
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
        
        var types: [[TopicTypeUI]] = []
        
        var isFirstPage = true
        var isLoadingTopic = true
        var isRefreshing = false
        
        var pageNavigation = PageNavigationFeature.State(type: .topic)
        
        var didLoadOnce = false
        
        public var isUserAuthorized: Bool {
            return userSession != nil
        }
        
        var shouldShowTopicHatButton = false
        
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
            case onAppear
            case onRefresh
            case onSceneBecomeActive
            case finishedPostAnimation
            case topicHatOpenButtonTapped
            case userTapped(Int)
            case urlTapped(URL)
            case imageTapped(URL)
            case contextMenu(TopicContextMenuAction)
            case contextPostMenu(TopicPostContextMenuAction)
            case editWarningSheetCloseButtonTapped
        }
        
        case `internal`(Internal)
        public enum Internal {
            case load
            case refresh
            case goToPost(postId: Int, offset: Int, forceRefresh: Bool)
            case loadTopic(Int)
            case loadTypes([[TopicTypeUI]])
            case topicResponse(Result<Topic, any Error>)
            case setFavoriteResponse(Bool)
            case jumpRequestFailed
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case handleUrl(URL)
            case openUser(id: Int)
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
                
            case .destination, .pageNavigation, .binding:
                return .none
                
            case .view(.onAppear):
                guard state.topic == nil else { return .none }
                return .send(.internal(.load))
                
            case .view(.onRefresh):
                return .send(.internal(.refresh))
                
            case .view(.onSceneBecomeActive):
                if state.isLoadingTopic || state.isRefreshing {
                    return .none
                } else {
                    return .send(.internal(.refresh))
                }
                
            case .view(.topicHatOpenButtonTapped):
                guard let topicHat = state.topic?.posts.first else { fatalError("No Topic Hat Found") }
                let topicHatNodes = TopicNodeBuilder(text: topicHat.content, attachments: topicHat.attachments).build()
                state.types[0] = topicHatNodes
                state.shouldShowTopicHatButton = false
                return .none
                
            case let .view(.userTapped(id)):
                return .send(.delegate(.openUser(id: id)))
                
            case let .view(.urlTapped(url)):
                return .send(.delegate(.handleUrl(url))) //handleUrl(url, &state)
                
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
                    
                case .writePostWithTemplate:
                    let feature = WriteFormFeature.State(
                        formFor: .post(
                            type: .new,
                            topicId: topic.id,
                            content: .template("")
                        )
                    )
                    state.destination = .writeForm(feature)
                    return .none
                    
                case .openInBrowser:
                    let url = URL(string: "https://4pda.to/forum/index.php?showtopic=\(topic.id)")!
                    return .run { _ in await open(url: url) }
                    
                case .copyLink:
                    pasteboardClient.copy("https://4pda.to/forum/index.php?showtopic=\(topic.id)")
                    return .none
                    
                case .setFavorite:
                    return .run { [id = state.topicId] send in
                        let request = SetFavoriteRequest(id: id, action: topic.isFavorite ? .delete : .add, type: .topic)
                        _ = try await apiClient.setFavorite(request)
                        await send(.internal(.setFavoriteResponse(!topic.isFavorite)))
                        
                        #warning("toast")
                    } catch: { error, send in
                        logger.error("Failed to set favorite: \(error)")
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
                    
                case .delete(let id):
                    return .concatenate(
                        .run { _ in
                            let status = try await apiClient.deletePosts(postIds: [id])
                            await toastClient.showToast(status ? .postDeleted : .whoopsSomethingWentWrong)
                        }.cancellable(id: CancelID.loading),
                        
                        jumpTo(.post(id: id), true, &state)
                    )
                }
                
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
                case .last:             return jumpTo(.last, false, &state)
                }
                
            case .internal(.refresh):
                state.isRefreshing = true
                return .run { [offset = state.pageNavigation.offset] send in
                    await send(.internal(.loadTopic(offset)))
                }
                
            case let .internal(.loadTopic(offset)):
                state.isFirstPage = offset == 0
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
                    
                    .run { [isFirstPage = state.isFirstPage, topicPerPage = state.appSettings.topicPerPage] send in
                        var topicTypes: [[TopicTypeUI]] = []
                        
                        topicTypes = await withTaskGroup(of: (Int, [TopicTypeUI]).self, returning: [[TopicTypeUI]].self) { taskGroup in
                            for (index, post) in topic.posts.enumerated() {
                                // guard index == 0 else { continue } // For test purposes
                                var text = post.content
                                // print(post)
                                if index == 0 && !isFirstPage {
                                    text = "" // Not loading hat post for non-first page
                                }
                                taskGroup.addTask {
                                    return (index, TopicNodeBuilder(text: text, attachments: post.attachments).build())
                                }
                            }
                            
                            var types = Array<[TopicTypeUI]?>(repeating: nil, count: topicPerPage + 1)
                            for await (index, result) in taskGroup {
                                types[index] = result
                            }
                            return types.map { $0 ?? [] }
                        }
                        await send(.internal(.loadTypes(topicTypes)))
                    }.cancellable(id: CancelID.loading),
                    
                    .run { [isLastPage = state.pageNavigation.isLastPage] send in
                        if isLastPage {
                            notificationCenter.send(notification: .favoritesUpdated)
                        }
                    }
                )
                
            case let .internal(.loadTypes(types)):
                state.types = types
                state.isLoadingTopic = false
                state.isRefreshing = false
                state.shouldShowTopicHatButton = !state.isFirstPage
                reportFullyDisplayed(&state)
                return .none
//                return PageNavigationFeature()
//                    .reduce(into: &state.pageNavigation, action: .nextPageTapped)
//                    .map(Action.pageNavigation)
                
            case .internal(.topicResponse(.failure)):
                state.isRefreshing = false
                reportFullyDisplayed(&state)
                return showToast(.whoopsSomethingWentWrong)
                
            case let .internal(.setFavoriteResponse(isFavorite)):
                state.topic?.isFavorite = isFavorite
                notificationCenter.send(.favoritesUpdated)
                return .none
                
            case .internal(.jumpRequestFailed):
                return showToast(.whoopsSomethingWentWrong)
                
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
    
    #warning("move")
    public enum JumpTo: Sendable {
        case unread
        case last
        case post(id: Int)
        
        var postId: Int {
            switch self {
            case .unread, .last: return 0
            case let .post(id):  return id
            }
        }
        
        var type: JumpForumRequest.ForumJumpType {
            switch self {
            case .unread:      return .new
            case .last:        return .last
            case .post:        return .post
            }
        }
    }
    
    private func jumpTo(_ jump: JumpTo, _ forceRefresh: Bool, _ state: inout State) -> Effect<Action> {
        return .run { [topicId = state.topicId, topicPerPage = state.appSettings.topicPerPage] send in
            let request = JumpForumRequest(postId: jump.postId, topicId: topicId, allPosts: true, type: jump.type)
            let response = try await apiClient.jumpForum(request)
            let offset = response.offset - (response.offset % topicPerPage)
            await send(.internal(.goToPost(postId: response.postId, offset: offset, forceRefresh: forceRefresh)))
        } catch: { error, send in
            await send(.internal(.jumpRequestFailed))
        }
    }
    
    private func handleUrl(_ url: URL, _ state: inout State) -> Effect<Action> {
        // If it's a snapback, we handle it locally (same or other page)
//        if url.scheme == "snapback", let postIdString = url.host(), let postId = Int(postIdString) {
//            return jumpTo(.post(id: postId), &state)
//        }
        
//        do {
//            let deeplink = try DeeplinkHandler().handleInnerToInnerURL(url)
//            if case let .topic(id: id, goTo: goTo) = deeplink {
//                if id == state.topicId {
//                    print("SAME TOPIC")
//                    switch goTo {
//                    case .first:            return loadPage(&state)
//                    case .unread:           return jumpTo(.unread, &state)
//                    case .post(id: let id): return jumpTo(.post(id: id), &state)
//                    case .last:             return jumpTo(.last, &state)
//                    }
//                } else {
//                    print("NON-SAME TOPIC")
//                }
//            }
//        } catch {
//            print(error)
//        }
        
//        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
//            if let value = components.queryItems?.first(where: { $0.name == "showtopic" })?.value {
//                if let topicId = Int(value) {
//                    if topicId == state.topicId {
//                        return jumpTo(.last, <#T##state: &State##State#>)
//                    }
//                }
//            }
//        }
        // If it's not, then we delegate it a layer up, to open new screen
        return .send(.delegate(.handleUrl(url)))
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
    
    private func showToast(_ toast: ToastMessage) -> Effect<Action> {
        return .run { _ in
            await toastClient.showToast(toast)
        }
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
