//
//  WriteFormFeature.swift
//  ForPDA
//
//  Created by Xialtal on 14.03.25.
//

import Foundation
import ComposableArchitecture
import APIClient
import Models

@Reducer
public struct WriteFormFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Presents var preview: FormPreviewFeature.State?
        
        public let formFor: WriteFormForType
        
        var textContent: String = ""
        
        var formFields: [WriteFormFieldType] = []
        
        var isFormLoading = true
        var isPublishing = false
        
        public init(
            formFor: WriteFormForType
        ) {
            self.formFor = formFor
        }
    }
    
    // MARK: - Action
    
    public enum Action {
        case onAppear
        
        case updateFieldContent(Int, String)
        
        case writeFormSent(WriteFormSend)
        
        case preview(PresentationAction<FormPreviewFeature.Action>)
        
        case publishButtonTapped
        case dismissButtonTapped
        case previewButtonTapped
        
        case _loadForm(id: Int, isTopic: Bool)
        case _formResponse(Result<[WriteFormFieldType], any Error>)
        case _simplePostResponse(Result<PostSend, any Error>)
        case _reportResponse(Result<ReportResponseType, any Error>)
    }
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                switch state.formFor {
                case .topic(let forumId, _):
                    return .send(._loadForm(id: forumId, isTopic: true))
                    
                case .post(let topicId, let type):
                    switch type {
                    case .simple(let content, _):
                        state.textContent = content
                        return .send(._formResponse(.success([
                            .editor(.init(
                                name: "",
                                description: "",
                                example: "",
                                flag: 0,
                                defaultValue: ""
                            ))
                        ])))
                        
                    case .template:
                        return .send(._loadForm(id: topicId, isTopic: false))
                    }
                    
                case .report:
                    return .send(._formResponse(.success([
                        .editor(.init(
                            name: "",
                            description: "",
                            example: "",
                            flag: 0,
                            defaultValue: ""
                        ))
                    ])))
                }
                
            case .publishButtonTapped:
                state.isPublishing = true
                switch state.formFor {
                case .post(let topicId, content: .simple(_, let attaches)):
                    return .run { [
                        topicId = topicId,
                        attachments = attaches,
                        content = state.textContent
                    ] send in
                        let request = PostRequest(
                            topicId: topicId,
                            content: content,
                            flag: 0,
                            attachments: attachments
                        )
                        let result = await Result { try await apiClient.sendPost(request: request) }
                        await send(._simplePostResponse(result))
                    }
                    
                case .report(let id, let type):
                    return .run { [
                        id = id,
                        type = type,
                        content = state.textContent
                    ] send in
                        let request = ReportRequest(id: id, type: type, message: content)
                        let result = await Result { try await apiClient.sendReport(request: request) }
                        await send(._reportResponse(result))
                    }
                    
                default:
                    return .none
                }
                
            case .preview:
                return .none
                
            case .previewButtonTapped:
                let topicId = if case .post(let topicId, _) = state.formFor { topicId } else { 0 }
                state.preview = FormPreviewFeature.State(formType: .post(
                    topicId: topicId,
                    content: .simple(state.textContent, [])
                ))
                return .none
                
            case .writeFormSent(let result):
                if case let .report(status) = result {
                    // Not closing form if error.
                    if status.isError {
                        return .none
                    }
                }
                return .run { _ in await dismiss() }
                
            case .dismissButtonTapped:
                return .run { _ in await dismiss() }
                
            case .updateFieldContent(_, let content):
                state.textContent = content
                return .none

            case let ._loadForm(id, isTopic):
                return .run { [id = id, isTopic = isTopic] send in
                    let result = await Result { try await apiClient.getTemplate(
                        request: ForumTemplateRequest(id: id, action: .get),
                        isTopic: isTopic
                    ) }
                    await send(._formResponse(result))
                } catch: { error, send in
                    await send(._formResponse(.failure(error)))
                }
                
            case let ._formResponse(.success(form)):
                state.formFields = form
                
                state.isFormLoading = false
                
                return .none
                
            case let ._formResponse(.failure(error)):
                print(error)
                return .none
                
            case let ._simplePostResponse(.success(post)):
                return .send(.writeFormSent(.post(PostSend(
                    id: post.id,
                    topicId: post.topicId,
                    offset: post.offset
                ))))
                
            case let ._simplePostResponse(.failure(error)):
                state.isPublishing = false
                print(error)
                return .none
                
            case let ._reportResponse(.success(result)):
                return .send(.writeFormSent(.report(result)))
                
            case let ._reportResponse(.failure(error)):
                state.isPublishing = false
                print(error)
                return .none
            }
        }
        .ifLet(\.$preview, action: \.preview) {
            FormPreviewFeature()
        }
    }
}
