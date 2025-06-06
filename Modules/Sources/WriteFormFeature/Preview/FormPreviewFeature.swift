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

@Reducer
public struct FormPreviewFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable, Sendable {
        public let formType: WriteFormForType
        
        var contentTypes: [TopicTypeUI] = []
        
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
        
        case _loadPreview(id: Int, content: String)
        case _loadSimplePreview(id: Int, content: String, attIds: [Int])
        case _previewResponse(Result<PostPreview, any Error>)
    }
    
    // MARK: - Dependencies
        
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.dismiss) var dismiss
        
    // MARK: - Body
            
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                switch state.formType {
                case .topic(let forumId, let content):
                    return .send(._loadPreview(id: forumId, content: content))
                    
                case .post(_, let topicId, let contentType):
                    switch contentType {
                    case .simple(let content, let attachments):
                        return .send(._loadSimplePreview(id: topicId, content: content, attIds: attachments))
                        
                    case .template(let content):
                        return .send(._loadPreview(id: topicId, content: content))
                    }
                    
                case .report(_, _):
                    // handling as .post
                    break
                }
                return .none
                
            case .cancelButtonTapped:
                return .run { _ in await dismiss() }
                
            case let ._loadPreview(id, content):
                state.isPreviewLoading = true
                return .run { [isTopic = state.formType.isTopic] send in
                    let result = await Result { try await apiClient.previewTemplate(
                        id: id,
                        content: content,
                        isTopic: isTopic
                    )}
                    await send(._previewResponse(result))
                } catch: { error, send in
                    await send(._previewResponse(.failure(error)))
                }
            
            case let ._loadSimplePreview(id, content, attachments):
                state.isPreviewLoading = true
                return .run { send in
                    let result = await Result { try await apiClient.previewPost(
                        request: PostPreviewRequest(
                            id: 0, // TODO: until we not adding support to edit post.
                            post: PostRequest(
                                topicId: id,
                                content: content,
                                flag: 0,
                                attachments: attachments
                            )
                        )
                    )}
                    await send(._previewResponse(result))
                } catch: { error, send in
                    await send(._previewResponse(.failure(error)))
                }
                
            case let ._previewResponse(.success(preview)):
                state.contentTypes = TopicNodeBuilder(
                    text: preview.content, attachments: []
                ).build()
                
                // TODO: Attachments.
                
                state.isPreviewLoading = false
                
                return .none
                
            case let ._previewResponse(.failure(error)):
                // TODO: Toast?
                print(error)
                return .send(.cancelButtonTapped)
            }
        }
    }
}
