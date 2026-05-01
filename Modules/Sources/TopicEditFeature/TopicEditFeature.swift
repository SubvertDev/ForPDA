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
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
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
        
        case view(View)
        public enum View {
            case onAppear
            
            case cancelButtonTapped
            
            case updateQuestion(Int, Topic.Poll.Option)
            case updateAnswerVotes(questionId: Int, answerId: Int, String)
            
            case addQuestionButtonTapped
            case removeQuestionButtonTapped(Int)
            
            case addAnswerButtonTapped(questionId: Int)
            case removeAnswerButtonTapped(questionId: Int, Int)
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
                
            case .binding:
                return .none
                
            case .view(.onAppear):
                if let poll = state.poll {
                    state.draftPoll = poll
                    state.isPollEnabled = true
                }
                return .none
                
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
            }
        }
    }
}
