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
    
    // MARK: - Helper Enums
    
    public enum PostSendFlag: Int, Sendable {
        case `default` = 0
        case attach = 1
        case doNotAttach = 3
    }
    
    // MARK: - Destinations
    
    @Reducer
    public enum Destination {
        case preview(FormPreviewFeature)
        case alert(AlertState<Alert>)
        
        @CasePathable
        public enum Alert {
            case attach
            case doNotAttach
            case dismiss
        }
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var destination: Destination.State?
        
        @Shared(.userSession) var userSession
        
        public let formFor: WriteFormForType
        
        var textContent = ""
        var isEditReasonToggleSelected = false
        var editReasonContent = ""
        var canShowShowMark = false
        var isShowMarkToggleSelected = false
        var inPostEditingMode: Bool {
            if case let .post(type, _, _) = formFor, case .edit = type {
                return true
            }
            return false
        }
        
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
    
    public enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        case destination(PresentationAction<Destination.Action>)
        
        case view(View)
        public enum View {
            case onAppear
            case updateFieldContent(Int, String)
            case publishButtonTapped
            case dismissButtonTapped
            case previewButtonTapped
        }
        
        case `internal`(Internal)
        public enum Internal {
            case publishPost(flag: PostSendFlag)
            case loadForm(id: Int, isTopic: Bool)
            case formResponse(Result<[WriteFormFieldType], any Error>)
            case simplePostResponse(Result<PostSendResponse, any Error>)
            case reportResponse(Result<ReportResponseType, any Error>)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case writeFormSent(WriteFormSend)
        }
    }
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.cacheClient) private var cacheClient
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                switch state.formFor {
                case .topic(let forumId, _):
                    return .send(.internal(.loadForm(id: forumId, isTopic: true)))
                    
                case .post(_, let topicId, let contentType):
                    if state.inPostEditingMode,
                       let userId = state.userSession?.userId,
                       let user = cacheClient.getUser(userId),
                       user.canSetShowMarkOnPostEdit {
                        state.canShowShowMark = true
                    }
                    switch contentType {
                    case .simple(let content, _):
                        state.textContent = content
                        let field: WriteFormFieldType = .editor(.init(
                            name: "",
                            description: "",
                            example: "",
                            flag: 0,
                            defaultValue: state.inPostEditingMode ? content : ""
                        ))
                        return .send(.internal(.formResponse(.success([field]))))
                        
                    case .template:
                        return .send(.internal(.loadForm(id: topicId, isTopic: false)))
                    }
                    
                case .report:
                    let field = WriteFormFieldType.editor(.init(
                        name: "",
                        description: "",
                        example: "",
                        flag: 0,
                        defaultValue: ""
                    ))
                    return .send(.internal(.formResponse(.success([field]))))
                }
                
            case .view(.publishButtonTapped):
                state.isPublishing = true
                return .send(.internal(.publishPost(flag: .default)))
                
            case .view(.previewButtonTapped):
                let topicId = if case .post(_, let topicId, _) = state.formFor { topicId } else { 0 }
                let type = if case .post(let type, _, _) = state.formFor { type } else { WriteFormForType.PostType.new }
                state.destination = .preview(
                    FormPreviewFeature.State(
                        formType: .post(
                            type: type,
                            topicId: topicId,
                            content: .simple(state.textContent, [])
                        )
                    )
                )
                return .none
                
            case .view(.dismissButtonTapped):
                return .run { _ in await dismiss() }
                
            case .view(.updateFieldContent(_, let content)):
                state.textContent = content
                return .none
            
            case let .internal(.publishPost(flag: postTypeFlag)):
                switch state.formFor {
                case .post(let type, let topicId, content: .simple(_, let attachments)):
                    let editPostFlag = state.isShowMarkToggleSelected ? 4 : 0
                    return .run { [editPostFlag, topicId, attachments, reason = state.editReasonContent, content = state.textContent] send in
                        switch type {
                        case .new:
                            var newPostFlag = 0
                            newPostFlag |= postTypeFlag.rawValue
                            let request = PostRequest(
                                topicId: topicId,
                                content: content,
                                flag: newPostFlag,
                                attachments: attachments
                            )
                            let result = await Result { try await apiClient.sendPost(request: request) }
                            await send(.internal(.simplePostResponse(result)))
                            
                        case .edit(postId: let postId):
                            let request = PostEditRequest(
                                postId: postId,
                                reason: reason,
                                data: PostRequest(
                                    topicId: topicId,
                                    content: content,
                                    flag: editPostFlag,
                                    attachments: attachments
                                )
                            )
                            let result = await Result { try await apiClient.editPost(request: request) }
                            await send(.internal(.simplePostResponse(result)))
                        }
                    }
                    
                case .report(let id, let type):
                    return .run { [id = id, type = type, content = state.textContent] send in
                        let request = ReportRequest(id: id, type: type, message: content)
                        let result = await Result { try await apiClient.sendReport(request: request) }
                        await send(.internal(.reportResponse(result)))
                    }
                    
                default:
                    return .none
                }

            case let .internal(.loadForm(id, isTopic)):
                return .run { [id = id, isTopic = isTopic] send in
                    let result = await Result { try await apiClient.getTemplate(
                        request: ForumTemplateRequest(id: id, action: .get),
                        isTopic: isTopic
                    ) }
                    await send(.internal(.formResponse(result)))
                } catch: { error, send in
                    await send(.internal(.formResponse(.failure(error))))
                }
                
            case let .internal(.formResponse(.success(form))):
                state.formFields = form
                
                state.isFormLoading = false
                
                return .none
                
            case let .internal(.formResponse(.failure(error))):
                print(error)
                return .none
                
            case let .internal(.simplePostResponse(.success(.success(post)))):
                return .send(.delegate(.writeFormSent(.post(.success(post)))))
                
            case let .internal(.simplePostResponse(.success(.failure(status)))):
                switch status {
                case .premoderation:
                    state.destination = .alert(.postIsSentToPremoderation)
                case .tooLong:
                    state.destination = .alert(.postIsTooLong)
                case .alreadySent:
                    state.destination = .alert(.postIsAlreadySent)
                case .attach:
                    state.destination = .alert(.attachToPreviousPost)
                case .unknown:
                    state.destination = .alert(.unknownError)
                }
                return .none
                
            case let .destination(.presented(.alert(action))):
                let editorFlag: Int
                switch action {
                case .attach:
                    editorFlag = 1
                case .doNotAttach:
                    editorFlag = 3
                case .dismiss:
                    return .run { _ in await dismiss() }
                }
                
                return .send(.internal(.publishPost(flag: PostSendFlag(rawValue: editorFlag)!)))
                
            case .destination(.dismiss):
                state.isPublishing = false
                return .none
                
            case let .internal(.simplePostResponse(.failure(error))):
                state.isPublishing = false
                print(error)
                return .none
                
            case let .internal(.reportResponse(.success(result))):
                return .send(.delegate(.writeFormSent(.report(result))))
                
            case let .internal(.reportResponse(.failure(error))):
                state.isPublishing = false
                print(error)
                return .none
                
            case .delegate(.writeFormSent(let result)):
                if case let .report(status) = result {
                    // Not closing form if error.
                    if status.isError {
                        return .none
                    }
                }
                return .run { _ in await dismiss() }
                
            case .binding(\.isEditReasonToggleSelected):
                if !state.isEditReasonToggleSelected {
                    state.editReasonContent = ""
                    state.isShowMarkToggleSelected = false
                }
                return .none
                
            case .binding, .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension WriteFormFeature.Destination.State: Equatable {}

// MARK: - Alert Extension

extension AlertState where Action == WriteFormFeature.Destination.Alert {
    
    nonisolated(unsafe) static let postIsSentToPremoderation = AlertState {
        TextState("Post is sent to premoderation")
    } actions: {
        ButtonState(action: .dismiss) {
            TextState("OK")
        }
    }
    
    nonisolated(unsafe) static let postIsTooLong = AlertState {
        TextState("Post is too long")
    } actions: {
        ButtonState {
            TextState("OK")
        }
    }
    
    nonisolated(unsafe) static let postIsAlreadySent = AlertState {
        TextState("Post is already sent")
    } actions: {
        ButtonState {
            TextState("OK")
        }
    }
    
    nonisolated(unsafe) static let attachToPreviousPost = AlertState {
        TextState("Attach this post to previous one?")
    } actions: {
        ButtonState(action: .attach) {
            TextState("Yes, attach")
        }
        ButtonState(action: .doNotAttach) {
            TextState("No, no need")
        }
    } message: {
        TextState("It will be attached as a dialog to your last post")
    }
    
    nonisolated(unsafe) static let unknownError = AlertState {
        TextState("Unknown error")
    } actions: {
        ButtonState {
            TextState("OK")
        }
    }
}
