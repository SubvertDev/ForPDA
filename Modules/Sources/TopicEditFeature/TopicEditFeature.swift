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
        }
        
        public let id: Int
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
            title: String,
            description: String,
            poll: Topic.Poll? = nil
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.poll = poll
        }
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction, BindableAction {
        case binding(BindingAction<State>)
        
        case view(View)
        public enum View {
            case onAppear
            
            case addQuestionButtonTapped
            case removeQuestionButtonTapped(Int)
            
            case addAnswerButtonTapped(questionId: Int)
            case removeAnswerButtonTapped(questionId: Int, Int)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case .binding(\.isPollEnabled):
                return .none
                
            case .view(.onAppear):
                if let poll = state.poll {
                    state.draftPoll = poll
                    state.isPollEnabled = true
                }
                return .none
                
            case .view(.addQuestionButtonTapped):
                let questionsCount = state.draftPoll.options.count
                state.draftPoll.options.append(.init(
                    id: questionsCount,
                    name: "",
                    several: false,
                    choices: []
                ))
                return .none
                
            case let .view(.removeQuestionButtonTapped(id)):
                state.draftPoll.options.remove(at: id)
                return .none
                
            case let .view(.addAnswerButtonTapped(questionId)):
                let answersCount = state.draftPoll.options[questionId].choices.count
                state.draftPoll.options[questionId].choices.append(
                    .init(id: answersCount, name: "", votes: 0)
                )
                return .none
                
            case let .view(.removeAnswerButtonTapped(questionId, answerId)):
                state.draftPoll.options[questionId].choices.remove(at: answerId)
                return .none
                
            case .binding:
                return .none
            }
        }
    }
}
