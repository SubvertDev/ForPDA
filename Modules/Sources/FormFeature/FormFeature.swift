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
    
    @Reducer
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
        public var isEditingReasonEnabled = false
        public var editReasonText = ""
        
        var isFormLocked = false
        
        var canShowShowMark = false
        var isShowMarkEnabled = false
        
        public var inPostEditingMode: Bool {
            if case let .post(type, _, _) = type, case .edit = type {
                return true
            }
            return false
        }
        
        var isPreviewButtonDisabled: Bool {
            if isFormLoading { return true }
            return !rows.filter { $0.isRequired() }.allSatisfy { $0.isValid() }
        }
        
        public var isPublishButtonDisabled: Bool {
            if isFormLoading { return true }
            return !rows.allSatisfy { $0.isValid() } || isPublishing
        }
        
        var content: [FormValue] {
            if case let .editor(editorState) = rows.first {
                if rows.count == 1 { // report
                    return [.string(editorState.text)]
                } else if rows.count == 2 { // simple post
                    let attachments = editorState.getAttachments()
                    return [.string(editorState.text), .array(attachments.map { .integer($0) })]
                } else {
                    fatalError("Incorrect data? \(rows)")
                }
            } else {
                var content: [FormValue] = []
                var combinedAttachments: [Int] = []
                for row in rows {
                    if case let .editor(state) = row, state.uploadBox != nil {
                        combinedAttachments = state.getAttachments()
                    } else if case let .uploadBox(state) = row, state.isHidden {
                        content.append(.array(combinedAttachments.map { .integer($0) }))
                    } else {
                        content.append(row.getValue())
                    }
                }
                return content
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
            case formResponse(Result<[FormFieldType], any Error>)
            case reportResponse(Result<ReportResponseType, any Error>)
            case simplePostResponse(Result<PostSendResponse, any Error>)
            case templateResponse(Result<TemplateSend, any Error>)
            case publishForm(flag: PostSendFlag)
        }
        
        case delegate(Delegate)
        @CasePathable
        public enum Delegate {
            case formSent(FormSend)
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
        
        Reduce<State, Action> { state, action in
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
                
                return .send(.internal(.publishForm(flag: PostSendFlag(rawValue: editorFlag)!)))
                
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
                    
                case .topic, .post:
                    // .formSent not called when an error occurs
                    break
                }
                return .run { _ in await dismiss() }
                
            case .delegate:
                break
                
            case let .rows(action):
                if case let .element(id: id, action: .uploadBox(.delegate(.anyFileUploading(status)))) = action {
                    state.isFormLocked = status
                    
                    // Lock all uploadboxes, exclude one that uploading.
                    for index in state.rows.indices {
                        if index != id, case var .uploadBox(uploadBoxState) = state.rows[id: index] {
                            uploadBoxState.isLocked = status
                        }
                    }
                }
                
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
                        let editorState = FormEditorFeature.State(
                            id: 0,
                            flag: [.required, .uploadable],
                            defaultText: content,
                            uploadBox: .init(id: 1, allowedExtensions: [])
                        )
                        let uploadBoxState = FormUploadBoxFeature.State(
                            id: 1,
                            title: "",
                            description: "",
                            flag: .uploadable,
                            allowedExtensions: [], // server will decide
                            isHidden: true
                        )
                        state.rows.append(.editor(editorState))
                        state.rows.append(.uploadBox(uploadBoxState))
                        state.focusedField = 0
                        
                    case .template:
                        state.isFormLoading = true
                        return .send(.internal(.loadForm(id: topicId, isTopic: false)))
                    }
                    
                case let .topic(forumId: forumId, content: _):
                    state.isFormLoading = true
                    return .send(.internal(.loadForm(id: forumId, isTopic: true)))
                    
                case .report:
                    let editorState = FormEditorFeature.State(id: 0, flag: .required, uploadBox: nil)
                    state.rows.append(.editor(editorState))
                    state.focusedField = 0
                }
                
            case .view(.cancelButtonTapped):
                return .run { _ in await dismiss() }
                
            case .view(.previewButtonTapped):
                let previewState: FormPreviewFeature.State
                switch state.type {
                case let .post(type: type, topicId: topicId, content: content):
                    let content = if case .simple = content {
                        if case let .string(text) = state.content.first,
                           case let .array(attachments) = state.content.last {
                            FormType.PostContentType.simple(
                                text,
                                FormValue.getIntArray(attachments).map { .init(id: $0, name: "", type: .file)}
                            )
                        } else {
                            fatalError("Bad simple post content! \(state.content)")
                        }
                    } else {
                        FormType.PostContentType.template(state.content)
                    }
                    
                    previewState = FormPreviewFeature.State(
                        formType: .post(type: type, topicId: topicId, content: content)
                    )
                    
                case .report:
                    let content = if case let .string(text) = state.content.first { text } else {
                        fatalError("Report content field should contains only one .string()!")
                    }
                    previewState = FormPreviewFeature.State(
                        formType: .post(type: .new, topicId: 0, content: .simple(content, []))
                    )
                    
                case let .topic(forumId: forumId, content: _):
                    previewState = FormPreviewFeature.State(
                        formType: .topic(forumId: forumId, content: state.content)
                    )
                }
                
                state.destination = .preview(previewState)
                
            case .view(.publishButtonTapped):
                return .send(.internal(.publishForm(flag: .default)))
                
            case let .internal(.loadForm(id: id, isTopic: isTopic)):
                return .run { send in
                    let request = ForumTemplateRequest(id: id, action: .get)
                    let result = await Result { try await apiClient.getTemplate(request, isTopic) }
                    await send(.internal(.formResponse(result)))
                } catch: { error, send in
                    await send(.internal(.formResponse(.failure(error))))
                }
                
            case let .internal(.formResponse(.success(fields))):
                var combined: (editorId: Int, uploadBox: FormStickedUploadBox?)? = nil
                for (index, field) in fields.enumerated() {
                    if case let .editor(content) = field, content.flag == [.required, .uploadable] {
                        combined = (index, nil)
                    } else if case let .uploadbox(content, extensions) = field {
                        if content.flag == [.required, .uploadable] {
                            combined = (combined!.editorId, .init(id: index, allowedExtensions: extensions))
                        } else if let editorId = combined?.editorId, index - 1 == editorId {
                            // if previous field is editor, that means editor supports upload
                            combined = (combined!.editorId, .init(id: index, allowedExtensions: extensions))
                        }
                    }
                }
                
                for (index, field) in fields.enumerated() {
                    switch field {
                    case let .title(content):
                        // do not skip empty titles, cause they are needed for future request building
                        let titleState = FormTitleFeature.State(id: index, text: content)
                        state.rows.append(.title(titleState))
                        
                    case let .text(content, maxLength):
                        let textFieldState = FormTextFieldFeature.State(
                            id: index,
                            title: content.name,
                            description: content.description,
                            placeholder: content.example,
                            flag: content.flag,
                            defaultText: content.defaultValue,
                            maxLength: maxLength
                        )
                        state.rows.append(.textField(textFieldState))
                        
                    case let .editor(content):
                        let editorState = FormEditorFeature.State(
                            id: index,
                            title: content.name,
                            description: content.description,
                            placeholder: content.example,
                            flag: content.flag,
                            defaultText: content.defaultValue,
                            uploadBox: index == combined?.editorId ? combined?.uploadBox : nil
                        )
                        state.rows.append(.editor(editorState))
                        
                    case let .checkboxList(content, options):
                        let checkboxListState = FormCheckBoxListFeature.State(
                            id: index,
                            title: content.name,
                            description: content.description,
                            flag: content.flag,
                            options: options
                        )
                        state.rows.append(.checkBoxList(checkboxListState))
                        
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
                            allowedExtensions: extensions,
                            isHidden: index == combined?.uploadBox?.id
                        )
                        state.rows.append(.uploadBox(uploadboxState))
                    }
                }
                state.isFormLoading = false
                
            case let .internal(.formResponse(.failure(error))):
                print(error)
                state.isFormLoading = false
                state.destination = .alert(.unknownError)
                
            case let .internal(.publishForm(flag: flag)):
                state.isPublishing = true
                switch state.type {
                case .topic(forumId: let id, content: _), .post(type: .new, topicId: let id, content: .template):
                    return .run { [isTopic = state.type.isTopic, content = state.content] send in
                        let content = try! FormValue.toDocument(content)
                        let result = await Result { try await apiClient.sendTemplate(id, content, isTopic) }
                        await send(.internal(.templateResponse(result)))
                    }
                    
                case let .post(type: type, topicId: topicId, content: .simple):
                    let editPostFlag = state.isShowMarkEnabled ? 4 : 0
                    let content = if case let .string(text) = state.content.first { text } else {
                        fatalError("Bad simple post content: \(state.content)")
                    }
                    let attachments = if case let .array(attachments) = state.content.last {
                        FormValue.getIntArray(attachments)
                    } else {
                        fatalError("Bad simple post attachments: \(state.content)")
                    }
                    return .run { [
                        content = content,
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
                    let content = if case let .string(text) = state.content.first { text } else {
                        fatalError("Simple content SHOULD be .string()!")
                    }
                    return .run { [content = content] send in
                        let request = ReportRequest(id: id, type: type, message: content)
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
                return .send(.delegate(.formSent(.post(post))))
                
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
                
            case let .internal(.templateResponse(.success(.success(result)))):
                switch result {
                case .post(let post):
                    return .send(.delegate(.formSent(.post(post))))
                case .topic(let id):
                    return .send(.delegate(.formSent(.topic(id))))
                }
                
            case let .internal(.templateResponse(.success(.failure(errorStatus)))):
                state.isPublishing = false
                switch errorStatus {
                case .badParam:
                    state.destination = .alert(.templateRequestHasBadParam)
                case .sentToPremod:
                    state.destination = .alert(.topicIsSentToPremoderation)
                case .fieldsError:
                    state.destination = .alert(.notAllFieldsAreFilledInTemplate)
                case .status(let status):
                    state.destination = .alert(.serverReturnStatusForTopic(status))
                }
                
            case let .internal(.templateResponse(.failure(error))):
                state.isPublishing = false
                state.destination = .alert(.unknownError)
                analyticsClient.capture(error)
            }
            
            return .none
        }
        .ifLet(\.$destination, action: \.destination)
        .forEach(\.rows, action: \.rows) {
            FormFieldFeature()
        }
        
        Analytics()
    }
}

extension FormFeature.Destination.State: Equatable {}

// MARK: - Alerts

public extension AlertState where Action == FormFeature.Destination.Alert {
    
    // Topic & Template
    
    nonisolated(unsafe) static let topicIsSentToPremoderation = AlertState {
        TextState("Topic is sent to premoderation")
    } actions: {
        ButtonState(action: .dismiss) {
            TextState("OK")
        }
    }
    
    nonisolated(unsafe) static let templateRequestHasBadParam = AlertState {
        TextState("The server refused to create the topic (invalid parameter)")
    } actions: {
        ButtonState {
            TextState("OK")
        }
    }
    
    nonisolated(unsafe) static let notAllFieldsAreFilledInTemplate = AlertState {
        TextState("Not all required fields are filled in")
    } actions: {
        ButtonState {
            TextState("OK")
        }
    }
    
    static func serverReturnStatusForTopic(_ status: Int) -> AlertState {
        return AlertState(
            title: { TextState("The server refused to create the topic (status \(status))") },
            actions: {
                ButtonState {
                    TextState("OK")
                }
            }
        )
    }
    
    // Post
    
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
