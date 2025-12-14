//
//  FormPreviewFeature.swift
//  ForPDA
//
//  Created by Xialtal on 16.03.25.
//

import Foundation
import ComposableArchitecture
import APIClient
import Models
import TopicBuilder
import SharedUI

@Reducer
public struct FormPreviewFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public let formType: WriteFormForType
        
        var contentTypes: [UITopicType] = []
        
        var isPreviewLoading = false
        
        public init(
            formType: WriteFormForType
        ) {
            self.formType = formType
        }
    }
    
    // MARK: - Action
            
    public enum Action {
        case onAppear
        
        case cancelButtonTapped
        
        case _loadSimplePreview(id: Int, content: String, attIds: [Int])
        case _simplePreviewResponse(Result<PostPreview, any Error>)
    }
    
    // MARK: - Dependencies
        
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.dismiss) var dismiss
        
    // MARK: - Body
            
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                if case let .post(_, topicId, contentType) = state.formType {
                    switch contentType {
                    case .simple(let content, let attachments):
                        return .send(._loadSimplePreview(id: topicId, content: content, attIds: attachments))
                        
                    // TODO: Think about correct type. Should be Any?
                    case .template(_): return .none
                    }
                }
                return .none
                
            case .cancelButtonTapped:
                return .run { _ in await dismiss() }

            case let ._loadSimplePreview(id, content, attachments):
                state.isPreviewLoading = true
                return .run { [
                    topicId = id,
                    content = content,
                    attachments = attachments
                ] send in
                    let result = await Result { try await apiClient.previewPost(
                        request: PostPreviewRequest(
                            id: 0, // TODO: until we not adding support to edit post.
                            post: PostRequest(
                                topicId: topicId,
                                content: content,
                                flag: 0,
                                attachments: attachments
                            )
                        )
                    )}
                    await send(._simplePreviewResponse(result))
                } catch: { error, send in
                    await send(._simplePreviewResponse(.failure(error)))
                }
                
            case let ._simplePreviewResponse(.success(preview)):
                state.contentTypes = TopicNodeBuilder(
                    text: preview.content, attachments: []
                ).build()
                
                // TODO: Attachments.
                
                state.isPreviewLoading = false
                
                return .none
                
            case let ._simplePreviewResponse(.failure(error)):
                // TODO: Toast?
                print(error)
                return .send(.cancelButtonTapped)
            }
        }
    }
}
