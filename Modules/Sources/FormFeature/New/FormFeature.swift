//
//  FormFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 19.07.2025.
//

import APIClient
import ComposableArchitecture
import Models

// MARK: - Form Feature

@Reducer
public struct FormFeature: Reducer, Sendable {
    
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
            case attach, doNotAttach, dismiss
        }
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var destination: Destination.State?
        
        @Shared(.userSession) var userSession
        
        let type: FormType
        public var rows: IdentifiedArrayOf<FormFieldFeature.State> = []
        public var focusedField: Int?
        public var isFormLoading = false
        public var isPublishing = false
        var canShowShowMark = false
        public var isEditingReasonEnabled = false
        var isShowMarkEnabled = false
        public var editReasonText = ""
        
        public var inPostEditingMode: Bool {
            if case let .post(type, _, _) = type, case .edit = type {
                return true
            }
            return false
        }
        
        var isPreviewButtonDisabled: Bool {
            return !rows.filter { $0.isRequired() }.allSatisfy { $0.isValid() }
        }
        
        public var isPublishButtonDisabled: Bool {
            return !rows.allSatisfy { $0.isValid() } || isPublishing
        }
        
        var content: String {
            if rows.count == 1, case let .editor(editorState) = rows.first {
                return editorState.text
            } else {
                let values = rows.map { $0.getValue() }
                return "[" + values.joined(separator: ",") + "]"
            }
        }
        
        public init(type: FormType) {
            self.type = type
        }
    }
    
    // MARK: - Actions
    
    public enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        case destination(PresentationAction<Destination.Action>)
        case rows(IdentifiedActionOf<FormFieldFeature>)

        case view(View)
        public enum View {
            case onAppear
            case cancelButtonTapped
            case previewButtonTapped
            case publishButtonTapped
        }
        
        case `internal`(Internal)
        @CasePathable
        public enum Internal {
            case loadForm(id: Int, isTopic: Bool)
            case formResponse(Result<[WriteFormFieldType], any Error>)
            case reportResponse(Result<ReportResponseType, any Error>)
            case simplePostResponse(Result<PostSendResponse, any Error>)
            case templateResponse(Result<TemplateSend, any Error>)
            case publishPost(flag: PostSendFlag)
        }
        
        case delegate(Delegate)
        @CasePathable
        public enum Delegate {
            case formSent(WriteFormSend)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.analyticsClient) private var analyticsClient
    @Dependency(\.cacheClient) private var cacheClient
    @Dependency(\.dismiss) private var dismiss
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> {
            state,
            action in
            switch action {
            case .binding(\.isEditingReasonEnabled):
                if !state.isEditingReasonEnabled {
                    state.editReasonText = ""
                    state.isShowMarkEnabled = false
                }
                
            case .binding:
                break
                
            case let .destination(.presented(.alert(action))):
                let editorFlag: Int
                switch action {
                case .attach:
                    editorFlag = PostSendFlag.attach.rawValue
                case .doNotAttach:
                    editorFlag = PostSendFlag.doNotAttach.rawValue
                case .dismiss:
                    return .run { _ in await dismiss() }
                }
                
                return .send(.internal(.publishPost(flag: PostSendFlag(rawValue: editorFlag)!)))
                
            case .destination(.dismiss):
                state.isPublishing = false
                
            case .destination:
                break
                
            case let .delegate(.formSent(result)):
                switch result {
                case let .report(status):
                    if status.isError {
                        return .none
                    }
                    
                case let .template(status):
                    if status.isError {
                        return .none
                    }
                    
                case let .post(status):
                    #warning("handle")
                    break
                }
                return .run { _ in await dismiss() }
                
            case .delegate:
                break
                
            case let .rows(action):
                if case let .element(id: id, action: .uploadBox(.delegate(.filesHasBeenUploaded))) = action {
                    if case let .uploadBox(uploadBoxState) = state.rows[id: id] {
                        print("Files: \(uploadBoxState.files)")
                    } else {
                        fatalError("Non UploadBox state casted by action id")
                    }
                }
                break
                
            case .view(.onAppear):
                switch state.type {
                case let .post(type: _, topicId: topicId, content: content):
                    if state.inPostEditingMode,
                       let userId = state.userSession?.userId,
                       let user = cacheClient.getUser(userId),
                       user.canSetShowMarkOnPostEdit {
                        state.canShowShowMark = true
                    }
                    
                    switch content {
                    case let .simple(content, _):
                        let editorState = FormEditorFeature.State(id: 0, flag: 1, defaultText: content)
                        state.rows.append(.editor(editorState))
                        state.focusedField = 0
                        
                    case .template:
                        state.isFormLoading = true
                        return .send(.internal(.loadForm(id: topicId, isTopic: false)))
                    }
                    
                case let .topic(forumId: forumId, content: _):
                    state.isFormLoading = true
                    return .send(.internal(.loadForm(id: forumId, isTopic: true)))
                    
                case .report:
                    let editorState = FormEditorFeature.State(id: 0, flag: 1)
                    state.rows.append(.editor(editorState))
                    state.focusedField = 0
                }
                
            case .view(.cancelButtonTapped):
                return .run { _ in await dismiss() }
                
            case .view(.previewButtonTapped):
                let previewState: FormPreviewFeature.State
                switch state.type {
                case let .post(type: type, topicId: topicId, content: content):
                    let content = if case .simple(_, let attachments) = content {
                        FormType.PostContentType.simple(state.content, attachments)
                    } else {
                        FormType.PostContentType.template(state.content)
                    }
                    
                    previewState = FormPreviewFeature.State(
                        formType: .post(type: type.convert(), topicId: topicId, content: content.convert())
                    )
                    
                case .report:
                    previewState = FormPreviewFeature.State(
                        formType: .post(type: .new, topicId: 0, content: .simple(state.content, []))
                    )
                    
                case let .topic(forumId: forumId, content: _):
                    previewState = FormPreviewFeature.State(
                        formType: .topic(forumId: forumId, content: state.content)
                    )
                }
                
                state.destination = .preview(previewState)
                
            case .view(.publishButtonTapped):
                return .send(.internal(.publishPost(flag: .default)))
//                return .run { send in
//                    await send(.internal(.publishPost(flag: .default)))
//                }
                
            case let .internal(.loadForm(id: id, isTopic: isTopic)):
                return .run { send in
                    let result = await Result { try await apiClient.getTemplate(id, isTopic) }
                    await send(.internal(.formResponse(result)))
                } catch: { error, send in
                    await send(.internal(.formResponse(.failure(error))))
                }
                
            case let .internal(.formResponse(.success(fields))):
                print(fields)
                state.isFormLoading = false
                for (index, field) in fields.enumerated() {
                    switch field {
                    case let .title(content):
                        guard !content.isEmpty else { continue }
                        let titleState = FormTitleFeature.State(id: index, text: content)
                        state.rows.append(.title(titleState))
                        
                    case let .text(content):
                        let textFieldState = FormTextFieldFeature.State(
                            id: index,
                            title: content.name,
                            description: content.description,
                            placeholder: content.example,
                            flag: content.flag,
                            defaultText: content.defaultValue
                        )
                        state.rows.append(.textField(textFieldState))
                        
                    case let .editor(content):
                        let editorState = FormEditorFeature.State(
                            id: index,
                            title: content.name,
                            description: content.description,
                            placeholder: content.example,
                            flag: content.flag,
                            defaultText: content.defaultValue
                        )
                        state.rows.append(.editor(editorState))
                        
                    case let .checkboxList(content, _):
                        let checkboxState = FormCheckBoxFeature.State(
                            id: index,
                            flag: content.flag
                        )
                        state.rows.append(.checkBox(checkboxState))
                        
                    case let .dropdown(content, options):
                        let dropdownState = FormDropdownFeature.State(
                            id: index,
                            title: content.name,
                            description: content.description,
                            flag: content.flag,
                            options: options
                        )
                        state.rows.append(.dropdown(dropdownState))
                        
                    case let .uploadbox(content, extensions):
                        let uploadboxState = FormUploadBoxFeature.State(
                            id: index,
                            title: content.name,
                            description: content.description,
                            flag: content.flag,
                            allowedExtensions: extensions
                        )
                        state.rows.append(.uploadBox(uploadboxState))
                    }
                }
                
            case let .internal(.formResponse(.failure(error))):
                print(error)
                state.isFormLoading = false
                state.destination = .alert(.unknownError)
                
            case let .internal(.publishPost(flag: flag)):
                state.isPublishing = true
                switch state.type {
                case .topic(forumId: let id, content: _), .post(type: .new, topicId: let id, content: .template):
                    return .run { [isTopic = state.type.isTopic, content = state.content] send in
                        let result = await Result { try await apiClient.sendTemplate(id: id, content: content, isTopic: isTopic) }
                        await send(.internal(.templateResponse(result)))
                    }
                    
                case let .post(type: type, topicId: topicId, content: .simple(_, attachments)):
                    let editPostFlag = state.isShowMarkEnabled ? 4 : 0
                    return .run { [
                        content = state.content,
                        reason = state.editReasonText
                    ] send in
                        switch type {
                        case .new:
                            var newPostFlag = 0
                            newPostFlag |= flag.rawValue
                            let request = PostRequest(
                                topicId: topicId,
                                content: content,
                                flag: newPostFlag,
                                attachments: attachments
                            )
                            let result = await Result { try await apiClient.sendPost(request) }
                            await send(.internal(.simplePostResponse(result)))
                            
                        case let .edit(postId: postId):
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
                            let result = await Result { try await apiClient.editPost(request) }
                            await send(.internal(.simplePostResponse(result)))
                        }
                    }
                    
                case let .report(id: id, type: type):
                    return .run { [content = state.content] send in
                        let request = ReportRequest(id: id, type: type.convert(), message: content)
                        let result = await Result { try await apiClient.sendReport(request) }
                        await send(.internal(.reportResponse(result)))
                    }
                    
                default:
                    fatalError()
                }
                
            case let .internal(.reportResponse(.success(report))):
                return .send(.delegate(.formSent(.report(report))))
            
            case let .internal(.reportResponse(.failure(error))):
                state.isPublishing = false
                state.destination = .alert(.unknownError)
                analyticsClient.capture(error)
                
            case let .internal(.simplePostResponse(.success(.success(post)))):
                return .send(.delegate(.formSent(.post(.success(post)))))
                
            case let .internal(.simplePostResponse(.success(.failure(errorStatus)))):
                state.isPublishing = false
                switch errorStatus {
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
            
            case let .internal(.simplePostResponse(.failure(error))):
                state.isPublishing = false
                state.destination = .alert(.unknownError)
                analyticsClient.capture(error)
                
            case let .internal(.templateResponse(.success(result))):
                return .send(.delegate(.formSent(.template(result))))
                
            case let .internal(.templateResponse(.failure(error))):
                state.isPublishing = false
                #warning("add error")
            }
            
            return .none
        }
        .ifLet(\.$destination, action: \.destination)
        .forEach(\.rows, action: \.rows) {
            FormFieldFeature()
        }
    }
}

// MARK: - Alerts

public extension AlertState where Action == FormFeature.Destination.Alert {
    
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
