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
    public struct State: Equatable, Sendable {
        public let formType: FormType
        
        var contentTypes: [UITopicType] = []
        var attachments: [Attachment] = []
        
        var isPreviewLoading = false
        
        public init(
            formType: FormType
        ) {
            self.formType = formType
        }
    }
    
    // MARK: - Action
            
    public enum Action: ViewAction {
        case view(View)
        public enum View {
            case onAppear
            case cancelButtonTapped
        }
        
        case `internal`(Internal)
        public enum Internal {
            case loadPreview(id: Int, content: [FormValue])
            case loadSimplePreview(postId: Int, topicId: Int, content: String, attIds: [Int])
            case previewResponse(Result<PreviewResponse, any Error>)
        }
    }
    
    // MARK: - Dependencies
        
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.analyticsClient) private var analyticsClient
    @Dependency(\.dismiss) var dismiss
        
    // MARK: - Body
            
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                switch state.formType {
                case .topic(let forumId, let content):
                    return .send(.internal(.loadPreview(id: forumId, content: content)))
                    
                case .post(let type, let topicId, let contentType):
                    switch contentType {
                    case .simple(let content, let attachments):
                        let postId = if case let .edit(id) = type { id } else { 0 }
                        let attachments = attachments.map { $0.id }
                        return .send(.internal(.loadSimplePreview(
                            postId: postId,
                            topicId: topicId,
                            content: content,
                            attIds: attachments
                        )))
                        
                    case .template(let content):
                        return .send(.internal(.loadPreview(id: topicId, content: content)))
                    }
                    
                case .report(_, _):
                    // handling as .post
                    break
                }
                return .none
                
            case .view(.cancelButtonTapped):
                return .run { _ in await dismiss() }
                
            case let .internal(.loadPreview(id, content)):
                state.isPreviewLoading = true
                return .run { [isTopic = state.formType.isTopic] send in
                    let result = await Result { try await apiClient.previewTemplate(
                        id: id,
                        content: try FormValue.toDocument(content),
                        isTopic: isTopic
                    )}
                    await send(.internal(.previewResponse(result)))
                } catch: { error, send in
                    await send(.internal(.previewResponse(.failure(error))))
                }
                
            case let .internal(.loadSimplePreview(postId, topicId, content, attachments)):
                state.isPreviewLoading = true
                return .run { send in
                    let result = await Result { try await apiClient.previewPost(
                        request: PostPreviewRequest(
                            id: postId,
                            post: PostRequest(
                                topicId: topicId,
                                content: content,
                                flag: 0,
                                attachments: attachments
                            )
                        )
                    )}
                    await send(.internal(.previewResponse(result)))
                } catch: { error, send in
                    await send(.internal(.previewResponse(.failure(error))))
                }
                
            case let .internal(.previewResponse(.success(preview))):
                state.contentTypes = TopicNodeBuilder(
                    text: preview.content, attachments: preview.attachments
                ).build()
                state.attachments = preview.attachments
                
                state.isPreviewLoading = false
                
                return .none
                
            case let .internal(.previewResponse(.failure(error))):
                analyticsClient.capture(error)
                return .send(.view(.cancelButtonTapped))
            }
        }
    }
}
