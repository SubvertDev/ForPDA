//
//  TopicEditFeature.swift
//  ForPDA
//
//  Created by Xialtal on 29.03.26.
//

import Foundation
import ComposableArchitecture
import APIClient
import Models

@Reducer
public struct TopicEditFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - Alert
    
    public enum Alert {
        case dismiss, ok
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var alert: AlertState<Alert>?
        
        public enum Field: Hashable {
            case title
            case description
            case pollName
            case pollQuestion(Int)
            case pollAnswer(questionId: Int, Int)
            case pollAnswerVote(questionId: Int, Int)
        }
        
        public let id: Int
        public let flag: ForumFlag
        public let supportsPoll: Bool
        
        public var canModerate: Bool {
            return flag.contains(.canModerate)
        }
        
        public var title: String
        public var description: String
        public var poll: Topic.Poll?
        
        var draftPoll = Topic.Poll(
            name: "",
            voted: false,
            totalVotes: 0,
            options: []
        )
        
        var focus: Field?
        var isSending = false
        var isPollEnabled = false
        
        var isSaveButtonDisabled: Bool {
            if !canModerate && !supportsPoll {
                return true
            }
            return title.isEmpty || (isPollEnabled && !isPollValid)
        }
        
        var isPollValid: Bool {
            guard !draftPoll.name.isEmpty, !draftPoll.options.isEmpty else {
                return false
            }
            for option in draftPoll.options {
                guard !option.name.isEmpty, !option.choices.isEmpty else {
                    return false
                }
                for choice in option.choices {
                    guard !choice.name.isEmpty else {
                        return false
                    }
                }
            }
            return true
        }
        
        public init(
            id: Int,
            flag: ForumFlag,
            title: String,
            description: String,
            poll: Topic.Poll? = nil,
            supportsPoll: Bool
        ) {
            self.id = id
            self.flag = flag
            self.title = title
            self.description = description
            self.poll = poll
            self.supportsPoll = supportsPoll
        }
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction, BindableAction {
        case binding(BindingAction<State>)
        case alert(PresentationAction<Alert>)
        
        case view(View)
        public enum View {
            case onAppear
            
            case saveButtonTapped
            case cancelButtonTapped
            
            case updateQuestion(Int, Topic.Poll.Option)
            case updateAnswerVotes(questionId: Int, answerId: Int, String)
            
            case addQuestionButtonTapped
            case removeQuestionButtonTapped(Int)
            
            case addAnswerButtonTapped(questionId: Int)
            case removeAnswerButtonTapped(questionId: Int, Int)
        }
        
        case `internal`(Internal)
        public enum Internal {
            case editResponse(Result<TopicEditResponse, any Error>)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case topicEdited
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.dismiss) private var dismiss
    @Dependency(\.apiClient) private var apiClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case .binding(\.isPollEnabled):
                if state.isPollEnabled {
                    state.focus = .pollName
                }
                return .none
                
            case .alert(.dismiss), .delegate(.topicEdited):
                return .run { _ in await dismiss() }
                
            case .binding, .alert, .delegate:
                return .none
                
            case .view(.onAppear):
                if let poll = state.poll {
                    state.draftPoll = poll
                    state.isPollEnabled = true
                }
                return .none
                
            case .view(.saveButtonTapped):
                let poll = state.isPollEnabled ? state.draftPoll : nil
                return .run { [
                    id = state.id,
                    title = state.title,
                    description = state.description,
                    poll = poll
                ] send in
                    let request = TopicEditRequest(
                        id: id,
                        title: title,
                        description: description,
                        poll: poll?.asDocument
                    )
                    let result = try await apiClient.editTopic(data: request)
                    await send(.internal(.editResponse(.success(result))))
                } catch: { error, send in
                    await send(.internal(.editResponse(.failure(error))))
                }
                
            case let .view(.updateQuestion(id, option)):
                guard let index = state.draftPoll.options.firstIndex(where: { $0.id == id }) else {
                    return .none
                }
                state.draftPoll.options[index] = option
                return .none
                
            case let .view(.updateAnswerVotes(questionId, answerId, votes)):
                if let questionIndex = state.draftPoll.options.firstIndex(where: { $0.id == questionId }),
                   let answerIndex = state.draftPoll.options[questionIndex].choices.firstIndex(where: { $0.id == answerId }) {
                    state.draftPoll.options[questionIndex].choices[answerIndex].votes = Int(votes) ?? 0
                }
                return .none
                
            case .view(.cancelButtonTapped):
                return .run { _ in await dismiss() }
                
            case .view(.addQuestionButtonTapped):
                let id = Int(Date.now.timeIntervalSince1970)
                state.draftPoll.options.append(.init(
                    id: id,
                    name: "",
                    several: false,
                    choices: []
                ))
                state.focus = .pollQuestion(id)
                return .none
                
            case let .view(.removeQuestionButtonTapped(id)):
                state.draftPoll.options.removeAll(where: { $0.id == id })
                return .none
                
            case let .view(.addAnswerButtonTapped(questionId)):
                let id = Int(Date.now.timeIntervalSince1970)
                if let index = state.draftPoll.options.firstIndex(where: { $0.id == questionId }) {
                    state.draftPoll.options[index].choices.append(
                        .init(id: id, name: "", votes: 0)
                    )
                    state.focus = .pollAnswer(questionId: questionId, id)
                }
                return .none
                
            case let .view(.removeAnswerButtonTapped(questionId, answerId)):
                if let questionIndex = state.draftPoll.options.firstIndex(where: { $0.id == questionId }),
                   let answerIndex = state.draftPoll.options[questionIndex].choices.firstIndex(where: { $0.id == answerId }) {
                    state.draftPoll.options[questionIndex].choices.remove(at: answerIndex)
                }
                return .none
                
            case let .internal(.editResponse(.success(status))):
                switch status {
                case .success:
                    return .send(.delegate(.topicEdited))
                case .tooManyQuestionsInPoll:
                    state.alert = .tooManyQuestionsInPoll
                case .tooManyAnswersInPoll:
                    state.alert = .tooManyAnswersInPoll
                case .inappropriateContent:
                    state.alert = .inappropriateContent
                case .sentToPremod:
                    state.alert = .topicIsSentToPremoderation
                case .noAccess:
                    state.alert = .noAccess
                }
                return .none
                
            case let .internal(.editResponse(.failure(error))):
                print(error)
                state.alert = .unknownError
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - Alerts

public extension AlertState where Action == TopicEditFeature.Alert {
    
    nonisolated(unsafe) static let topicIsSentToPremoderation = AlertState {
        TextState("Topic is sent to premoderation")
    } actions: {
        ButtonState(action: .dismiss) {
            TextState("OK")
        }
    }
    
    nonisolated(unsafe) static let tooManyQuestionsInPoll = AlertState {
        TextState("Too many questions in poll", bundle: .module)
    } actions: {
        ButtonState(action: .ok) {
            TextState("OK")
        }
    }
    
    nonisolated(unsafe) static let tooManyAnswersInPoll = AlertState {
        TextState("Too many answers in poll", bundle: .module)
    } actions: {
        ButtonState(action: .ok) {
            TextState("OK")
        }
    }
    
    nonisolated(unsafe) static let inappropriateContent = AlertState {
        TextState("Inappropriate content", bundle: .module)
    } actions: {
        ButtonState(action: .ok) {
            TextState("OK")
        }
    }
    
    nonisolated(unsafe) static let noAccess = AlertState {
        TextState("No access", bundle: .module)
    } actions: {
        ButtonState(action: .ok) {
            TextState("OK")
        }
    }
    
    nonisolated(unsafe) static let unknownError = AlertState {
        TextState("Unknown error", bundle: .module)
    } actions: {
        ButtonState(action: .ok) {
            TextState("OK")
        }
    }
}
