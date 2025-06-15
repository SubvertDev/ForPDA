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
    
    @Reducer(state: .equatable)
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
        
        var content: [Int: FormContentData] = [:]

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
        
        var isSubmitDisabled: Bool {
            !isFieldsValid(fields: formFields, content: content)
        }
        
        var textContent: String {
            if content.count == 1, case .text(let content) = content[0] {
                content
            } else { buildContent(fields: content) }
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
    
    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case destination(PresentationAction<Destination.Action>)
        
        case onAppear
        
        case updateContent(Int, FormContentData)
        
        case writeFormSent(WriteFormSend)
        
        case publishButtonTapped
        case dismissButtonTapped
        case previewButtonTapped
        
        case _publishPost(flag: PostSendFlag)
        
        case _loadForm(id: Int, isTopic: Bool)
        case _formResponse(Result<[WriteFormFieldType], any Error>)
        case _templateResponse(Result<TemplateSend, any Error>)
        case _simplePostResponse(Result<PostSendResponse, any Error>)
        case _reportResponse(Result<ReportResponseType, any Error>)
    }
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.cacheClient) private var cacheClient
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                switch state.formFor {
                case .topic(let forumId, _):
                    return .send(._loadForm(id: forumId, isTopic: true))
                    
                case .post(_, let topicId, let contentType):
                    if state.inPostEditingMode,
                       let userId = state.userSession?.userId,
                       let user = cacheClient.getUser(userId),
                       user.canSetShowMarkOnPostEdit {
                        state.canShowShowMark = true
                    }
                    switch contentType {
                    case .simple(let content, _):
                        state.content[0] = .text(content)
                        return .send(._formResponse(.success([
                            .editor(.init(
                                id: 0,
                                name: "",
                                description: "",
                                example: "",
                                flag: 1,
                                defaultValue: state.inPostEditingMode ? content : ""
                            ))
                        ])))
                        
                    case .template:
                        return .send(._loadForm(id: topicId, isTopic: false))
                    }
                    
                case .report:
                    return .send(._formResponse(.success([
                        .editor(.init(
                            id: 0,
                            name: "",
                            description: "",
                            example: "",
                            flag: 1,
                            defaultValue: ""
                        ))
                    ])))
                }
                
            case .publishButtonTapped:
                state.isPublishing = true
                return .send(._publishPost(flag: .default))
            
            case let ._publishPost(flag: postTypeFlag):
                switch state.formFor {
                case .topic(let id, _), .post(type: .new, let id, content: .template(_)):
                    return .run { [isTopic = state.formFor.isTopic, content = state.textContent] send in
                        let result = await Result { try await apiClient.sendTemplate(
                            id: id,
                            content: content,
                            isTopic: isTopic
                        ) }
                        await send(._templateResponse(result))
                    }
                    
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
                            await send(._simplePostResponse(result))
                            
                        case .edit(let postId):
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
                            await send(._simplePostResponse(result))
                        }
                    }
                    
                case .report(let id, let type):
                    return .run { [content = state.textContent] send in
                        let request = ReportRequest(id: id, type: type, message: content)
                        let result = await Result { try await apiClient.sendReport(request: request) }
                        await send(._reportResponse(result))
                    }
                    
                default:
                    return .none
                }
                
            case .previewButtonTapped:
                switch state.formFor {
                case .topic(let forumId, _):
                    state.destination = .preview(FormPreviewFeature.State(formType: .topic(forumId: forumId, content: state.textContent)))
                    
                case .post(let type, let topicId, let content):
                    let data = if case .simple(_, let attachments) = content {
                        WriteFormForType.PostContentType.simple(state.textContent, attachments)
                    } else {
                        WriteFormForType.PostContentType.template(state.textContent)
                    }
                    state.destination = .preview(FormPreviewFeature.State(formType: .post(type: type, topicId: topicId, content: data)))
                    
                case .report:
                    state.destination = .preview(FormPreviewFeature.State(formType: .post(type: .new, topicId: 0, content: .simple(state.textContent, []))))
                }
                return .none
                
            case .writeFormSent(let result):
                // Not closing form if error.
                switch result {
                case .report(let status):
                    if status.isError {
                        return .none
                    }
                    
                case .template(let status):
                    if status.isError {
                        return .none
                    }
                    
                // TODO: handle.
                case .post: break
                }
                return .run { _ in await dismiss() }
                
            case .dismissButtonTapped:
                return .run { _ in await dismiss() }
                
            case let .updateContent(fieldId, data):
                switch data {
                case .text(let content):
                    state.content[fieldId] = .text(content)
                
                case .dropdown(let id, let name):
                    state.content[fieldId] = .dropdown(id, name)
                
                case .uploadbox(let data):
                    // TODO: Implement
                    return .none
                    
                case .checkbox(let data):
                    let new = if case .checkbox(let ndata) = state.content[fieldId] {
                        data.reduce(into: ndata) { result, entry in
                            result[entry.key] = entry.value
                        }
                    } else { data }
                    state.content[fieldId] = .checkbox(new)
                }
                return .none

            case let ._loadForm(id, isTopic):
                return .run { send in
                    let result = await Result { try await apiClient.getTemplate(id: id, isTopic: isTopic) }
                    await send(._formResponse(result))
                } catch: { error, send in
                    await send(._formResponse(.failure(error)))
                }
                
            case let ._formResponse(.success(form)):
                state.formFields = form
                
                state.isFormLoading = false

                for (key, field) in form.enumerated() {
                    switch field {
                    case .title:
                        state.content[key] = .text("")
                        
                    case .text(let content), .editor(let content):
                        state.content[content.id] = .text(content.defaultValue)
                        
                    case .checkboxList(let content, _):
                        state.content[content.id] = .checkbox([0: false])
                        
                    case .dropdown(let content, let options):
                        state.content[content.id] = .dropdown(0, options[0])
                        
                    case .uploadbox(let content, _):
                        // TODO: Implement file upload.
                        state.content[content.id] = .uploadbox([])
                    }
                }
                
                return .none
                
            case let ._formResponse(.failure(error)):
                print(error)
                return .none
                
            case let ._simplePostResponse(.success(.success(post))):
                return .send(.writeFormSent(.post(.success(post))))
                
            case let ._simplePostResponse(.success(.failure(status))):
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
                
                return .send(._publishPost(flag: PostSendFlag(rawValue: editorFlag)!))
                
            case .destination(.dismiss):
                state.isPublishing = false
                return .none

            case let ._templateResponse(.success(result)):
                return .send(.writeFormSent(.template(result)))
                
            case let ._templateResponse(.failure(error)):
                state.isPublishing = false
                print(error)
                return .none
                
            case let ._simplePostResponse(.success(response)):
                switch response {
                case let .success(post):
                    return .send(.writeFormSent(.post(.success(PostSend(id: post.id, topicId: post.topicId, offset: post.offset)))))
                case let .failure(error):
                    // TODO: ???
                    print(error)
                }
                
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

// MARK: - Helpers

private extension WriteFormFeature {
    static func buildContent(fields: [Int: FormContentData]) -> String {
        var request: [Any] = []
        for (_, field) in fields.sorted(by: { $0.0 < $1.0 }) {
            switch field {
            case .text(let content):
                request.append(content)
            
            case .checkbox(let content):
                request.append(content
                    .filter { $0.value == true }
                    .map { $0.key + 1 } )
                
            case .dropdown(let id, _):
                request.append(id + 1)
                
            case .uploadbox(_):
                // TODO: Implement.
                request.append([])
            }
        }
        return request.description
    }

    static func isFieldsValid(fields: [WriteFormFieldType], content: [Int: FormContentData]) -> Bool {
        for field in fields {
            switch field {
            case .title(_): continue
                
            case .text(let info), .editor(let info), .dropdown(let info, _),
                 .checkboxList(let info, _), .uploadbox(let info, _):
                switch content[info.id] {
                case .text(let data):
                    if info.isRequired && data.isEmpty {
                        return false
                    }

                case .uploadbox(let data):
                    if info.isRequired && data.isEmpty {
                        return false
                    }
                    
                case .checkbox(let data):
                    if info.isRequired && data.isEmpty {
                        return false
                    }
                    
                // always initialized with default value
                case .dropdown: continue
                    
                case .none: return false
                }
            }
        }
        return true
    }
}
