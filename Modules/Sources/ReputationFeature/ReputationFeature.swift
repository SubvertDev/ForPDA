//
//  ReputationFeature.swift
//  ForPDA
//
//  Created by Рустам Ойтов on 11.07.2025.
//

import Foundation
import AnalyticsClient
import ComposableArchitecture
import APIClient
import Models
import FormFeature
import ToastClient
import CacheClient

@Reducer
public struct ReputationFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - Localizations
    
    public enum Localization {
        static let reportSent = LocalizedStringResource("Report sent", bundle: .module)
        static let reputationDeleted = LocalizedStringResource("Reputation deleted", bundle: .module)
        static let reputationRestored = LocalizedStringResource("Reputation restored", bundle: .module)
    }
    
    // MARK: - Destinations
    
    @Reducer
    public enum Destination {
        @ReducerCaseIgnored
        case alert(AlertState<Alert>)
        case report(FormFeature)
        
        @CasePathable
        public enum Action {
            case alert(Alert)
            case report(FormFeature.Action)
        }
        
        @CasePathable
        public enum Alert: Equatable {
            case ok
            case modifyVote(Int, ReputationModifyActionType)
        }
    }
    
    // MARK: - Picker Section
    
    enum PickerSection: Int {
        case history = 1
        case votes = 2
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var destination: Destination.State?
        @Shared(.userSession) var userSession: UserSession?
        var userSessionInfo: User?
        
        public let userId: Int
        public var isLoading = true
        public var historyData: [ReputationVote] = []
        var pickerSection: PickerSection = .history
        
        public var loadAmount = 20
        public var offset = 0
        
        public var isOwnVotes: Bool {
            return userSession?.userId == userId
        }
        
        public var isUserAuthorized: Bool {
            return userSession != nil
        }
        
        var isUserSessionHasModerationGroup: Bool {
            return userSessionInfo?.group == .admin
                || userSessionInfo?.group == .supermoderator
                || userSessionInfo?.group == .moderator
                || userSessionInfo?.group == .moderatorHelper
                || userSessionInfo?.group == .moderatorSchool
        }
        
        public init(userId: Int) {
            self.userId = userId
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction, ViewAction {
        case destination(PresentationAction<Destination.Action>)
        case binding(BindingAction<State>)
        
        case view(View)
        public enum View {
            case onAppear
            case loadMore
            case refresh
            case profileTapped(Int)
            case sourceTapped(ReputationVote)
            
            case contextVoteMenu(ReputationVoteContextMenuAction)
        }
        
        case `internal`(Internal)
        public enum Internal {
            case loadData
            case historyResponse(Result<ReputationVotes, any Error>)
            case modifyResponse(Result<(Int, ReputationModifyActionType, Bool), any Error>)
            
            case initUserSessionInfo(User)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case openProfile(profileId: Int)
            case openTopic(topicId: Int, name: String, goTo: GoTo)
            case openArticle(articleId: Int)
        }
    }
    
    // MARK: - CancelID
    
    enum CancelID {
        case loadData
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.analyticsClient) private var analyticsClient
    @Dependency(\.cacheClient) private var cacheClient
    @Dependency(\.toastClient) private var toastClient
    
    // MARK: - body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case .binding(\.pickerSection):
                state.historyData = []
                state.offset = 0
                state.isLoading = true
                return .send(.internal(.loadData))
                    .merge(with: .cancel(id: CancelID.loadData))
                
            case .destination(.presented(.report(.delegate(.formSent(.report))))):
                return .run { _ in
                    await toastClient.showToast(ToastMessage(text: Localization.reportSent, haptic: .success))
                }
                
            case let .destination(.presented(.alert(.modifyVote(voteId, type)))):
                return .run { send in
                    let status = try await apiClient.modifyReputation(voteId, type)
                    await send(.internal(.modifyResponse(.success((voteId, type, status)))))
                } catch: { error, send in
                    await send(.internal(.modifyResponse(.failure(error))))
                }
                
            case .view(.onAppear):
                return .run { [session = state.userSession] send in
                    if let session, let user = cacheClient.getUser(session.userId) {
                        await send(.internal(.initUserSessionInfo(user)))
                    }
                    await send(.internal(.loadData))
                }
                
            case .view(.loadMore):
                guard !state.isLoading else { return .none }
                guard !state.historyData.isEmpty else { return .none }
                return .send(.internal(.loadData))
                
            case .view(.refresh):
                state.offset = 0
                return .send(.internal(.loadData))
                
            case let .view(.profileTapped(profileId)):
                return .send(.delegate(.openProfile(profileId: profileId)))
                
            case let .view(.sourceTapped(vote)):
                switch vote.createdIn {
                case .profile:
                    return .send(.delegate(.openProfile(profileId: vote.authorId)))
                    
                case let .topic(id: topicId, topicName: topicName, postId: postId):
                    return .send(.delegate(.openTopic(topicId: topicId, name: topicName, goTo: .post(id: postId))))
                    
                case let .site(id: articleId, _, _):
                    return .send(.delegate(.openArticle(articleId: articleId)))
                }
                
            case let .view(.contextVoteMenu(action)):
                switch action {
                case .report(let voteId):
                    let feature = FormFeature.State(
                        type: .report(id: voteId, type: .reputation)
                    )
                    state.destination = .report(feature)
                    
                case .modify(let voteId, let type):
                    state.destination = .alert(.modifyVoteConfirmation(voteId: voteId, type: type))
                    
                case .goToAuthor(let profileId):
                    return .send(.delegate(.openProfile(profileId: profileId)))
                }
                return .none
                
            case .internal(.loadData):
                let isHistory = state.pickerSection == .history
                return .run { [userId = state.userId, offset = state.offset, amount = state.loadAmount] send in
                    let request = ReputationVotesRequest(
                        userId: userId,
                        type: isHistory ? .to : .from,
                        offset: offset,
                        amount: amount
                    )
                    let result = await Result {
                        try await apiClient.getReputationVotes(data: request)
                    }
                    await send(.internal(.historyResponse(result)))
                }
                .cancellable(id: CancelID.loadData)
                
            case let .internal(.historyResponse(.success(votes))):
                if state.offset == 0 {
                    state.historyData.removeAll()
                }
                state.historyData.append(contentsOf: votes.votes)
                state.offset += state.loadAmount
                state.isLoading = false
                analyticsClient.reportFullyDisplayed()
                return .none
                
            case let .internal(.historyResponse(.failure(error))):
                print(error)
                state.isLoading = false
                state.destination = .alert(.error)
                analyticsClient.reportFullyDisplayed()
                return .none
                
            case let .internal(.modifyResponse(.success((voteId, type, status)))):
                if let userSession = state.userSessionInfo, status,
                   let voteIndex = state.historyData.firstIndex(where: { $0.id == voteId }) {
                    let modified = ReputationVote.VoteModified(
                        userId: userSession.id,
                        userName: userSession.nickname,
                        modifiedAt: Date.now,
                        isDenied: type == .delete
                    )
                    state.historyData[voteIndex].modified = modified
                }
                return .run { _ in
                    let reputationToast = ToastMessage(
                        text: type == .delete ? Localization.reputationDeleted : Localization.reputationRestored,
                        haptic: .success
                    )
                    await toastClient.showToast(status ? reputationToast : .whoopsSomethingWentWrong)
                }
                
            case let .internal(.modifyResponse(.failure(error))):
                print(error)
                return .run { _ in await toastClient.showToast(.whoopsSomethingWentWrong) }
                
            case let .internal(.initUserSessionInfo(user)):
                state.userSessionInfo = user
                return .none
                
            case .delegate, .binding, .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        
        Analytics()
    }
}

extension ReputationFeature.Destination.State: Equatable {}

// MARK: - Alert Extension

extension AlertState where Action == ReputationFeature.Destination.Alert {
    
    nonisolated static func modifyVoteConfirmation(voteId: Int, type: ReputationModifyActionType) -> AlertState {
        return AlertState(
            title: {
                switch type {
                case .delete:  TextState("Are you sure, that you want to delete this vote?", bundle: .module)
                case .restore: TextState("Are you sure, that you want to restore this vote?", bundle: .module)
                }
            },
            actions: {
                ButtonState(role: type == .delete ? .destructive : nil, action: .modifyVote(voteId, type)) {
                    TextState("Yes", bundle: .module)
                }
                ButtonState(role: .cancel) {
                    TextState("No", bundle: .module)
                }
            }
        )
    }
    
    nonisolated(unsafe) static let error = Self {
        TextState("Whoops!", bundle: .module)
    } actions: {
        ButtonState(role: .cancel, action: .ok) {
            TextState("OK")
        }
    } message: {
        TextState("Something went wrong while loading reputation :(", bundle: .module)
    }
}
