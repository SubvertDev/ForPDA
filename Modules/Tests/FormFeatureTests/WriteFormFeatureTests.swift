//
//  WriteFormFeatureTests.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 08.08.2025.
//

import APIClient
import ComposableArchitecture
import Foundation
import Models
import Testing
import FormFeature

@MainActor
struct WriteFormFeatureTests {
    
    // MARK: - Report Success
    
    @Test func reportSuccess() async throws {
        let store = TestStore(
            initialState: FormFeature.State(type: .report(id: 0, type: .comment))
        ) {
            FormFeature()
        } withDependencies: {
            $0.apiClient.sendReport = { _ in
                return .success
            }
        }
        
        var editorState = FormEditorFeature.State(id: 0, flag: 1)
        await store.send(.view(.onAppear)) {
            $0.rows = [.editor(editorState)]
            $0.focusedField = 0
        }
        
        #expect(store.state.isPublishButtonDisabled)
        
        await store.send(.rows(.element(id: 0, action: .editor(.binding(.set(\.text, "text")))))) {
            editorState.text = "text"
            $0.rows[id: 0] = .editor(editorState)
        }
        
        #expect(!store.state.isPublishButtonDisabled)
        
        await store.send(.view(.publishButtonTapped))
        
        await store.receive(\.internal.publishPost) {
            $0.isPublishing = true
        }
        
        await store.receive(\.internal.reportResponse)
        
        await store.receive(\.delegate.formSent)
    }
    
    // MARK: - Report Network Failure
    
    @Test func reportNetworkFailure() async throws {
        let store = TestStore(
            initialState: FormFeature.State(type: .report(id: 0, type: .comment))
        ) {
            FormFeature()
        } withDependencies: {
            $0.apiClient.sendReport = { _ in
                throw NSError(domain: "network", code: 0)
            }
        }
        
        var editorState = FormEditorFeature.State(id: 0, flag: 1)
        await store.send(.view(.onAppear)) {
            $0.rows = [.editor(editorState)]
            $0.focusedField = 0
        }
        
        #expect(store.state.isPublishButtonDisabled)
        
        await store.send(.rows(.element(id: 0, action: .editor(.binding(.set(\.text, "text")))))) {
            editorState.text = "text"
            $0.rows[id: 0] = .editor(editorState)
        }
        
        #expect(!store.state.isPublishButtonDisabled)
        
        await store.send(.view(.publishButtonTapped))
        
        await store.receive(\.internal.publishPost) {
            $0.isPublishing = true
        }
        
        await store.receive(\.internal.reportResponse) {
            $0.isPublishing = false
            $0.destination = .alert(.unknownError)
        }
    }
    
    // MARK: - New Post Success
    
    @Test func newPostSuccess() async throws {
        let store = TestStore(
            initialState: FormFeature.State(
                type: .post(
                    type: .new,
                    topicId: 0,
                    content: .simple("", [])
                )
            )
        ) {
            FormFeature()
        } withDependencies: {
            $0.apiClient.sendPost = { _ in
                return .success(PostSend(id: 0, topicId: 0, offset: 0))
            }
        }
        
        var editorState = FormEditorFeature.State(id: 0, flag: 1, defaultText: "")
        await store.send(.view(.onAppear)) {
            $0.rows = [.editor(editorState)]
            $0.focusedField = 0
        }
        
        #expect(store.state.isPublishButtonDisabled)
        
        await store.send(.rows(.element(id: 0, action: .editor(.binding(.set(\.text, "text")))))) {
            editorState.text = "text"
            $0.rows[id: 0] = .editor(editorState)
        }
        
        #expect(!store.state.isPublishButtonDisabled)
        
        await store.send(.view(.publishButtonTapped))

        await store.receive(\.internal.publishPost) {
            $0.isPublishing = true
        }
        
        await store.receive(\.internal.simplePostResponse)
        
        await store.receive(\.delegate.formSent)
    }
    
    // MARK: - New Post Error Status
    
    @Test func newPostErrorStatus() async throws {
        let store = TestStore(
            initialState: FormFeature.State(
                type: .post(
                    type: .new,
                    topicId: 0,
                    content: .simple("", [])
                )
            )
        ) {
            FormFeature()
        } withDependencies: {
            $0.apiClient.sendPost = { _ in
                return .failure(.unknown)
            }
        }
        
        var editorState = FormEditorFeature.State(id: 0, flag: 1, defaultText: "")
        await store.send(.view(.onAppear)) {
            $0.rows = [.editor(editorState)]
            $0.focusedField = 0
        }
        
        #expect(store.state.isPublishButtonDisabled)
        
        await store.send(.rows(.element(id: 0, action: .editor(.binding(.set(\.text, "text")))))) {
            editorState.text = "text"
            $0.rows[id: 0] = .editor(editorState)
        }
        
        #expect(!store.state.isPublishButtonDisabled)
        
        await store.send(.view(.publishButtonTapped))

        await store.receive(\.internal.publishPost) {
            $0.isPublishing = true
        }
        
        await store.receive(\.internal.simplePostResponse) {
            $0.isPublishing = false
            $0.destination = .alert(.unknownError)
        }
    }
    
    // MARK: - New Post Attach Status
    
    @Test func newPostAttachStatus() async throws {
        let store = TestStore(
            initialState: FormFeature.State(
                type: .post(
                    type: .new,
                    topicId: 0,
                    content: .simple("", [])
                )
            )
        ) {
            FormFeature()
        } withDependencies: {
            $0.apiClient.sendPost = { request in
                if request.flag == 0 {
                    return .failure(.attach)
                } else {
                    return .success(PostSend(id: 0, topicId: 0, offset: 0))
                }
            }
        }
        
        var editorState = FormEditorFeature.State(id: 0, flag: 1, defaultText: "")
        await store.send(.view(.onAppear)) {
            $0.rows = [.editor(editorState)]
            $0.focusedField = 0
        }
        
        #expect(store.state.isPublishButtonDisabled)
        
        await store.send(.rows(.element(id: 0, action: .editor(.binding(.set(\.text, "text")))))) {
            editorState.text = "text"
            $0.rows[id: 0] = .editor(editorState)
        }
        
        #expect(!store.state.isPublishButtonDisabled)
        
        await store.send(.view(.publishButtonTapped))

        await store.receive(\.internal.publishPost) {
            $0.isPublishing = true
        }
        
        await store.receive(\.internal.simplePostResponse) {
            $0.isPublishing = false
            $0.destination = .alert(.attachToPreviousPost)
        }
        
        await store.send(.destination(.presented(.alert(.attach)))) {
            $0.destination = nil
        }
        
        await store.receive(\.internal.publishPost) {
            $0.isPublishing = true
        }
        
        await store.receive(\.internal.simplePostResponse)
        
        await store.receive(\.delegate.formSent)
    }
    
    // MARK: - New Post Network Failure
    
    @Test func newPostNetworkFailure() async throws {
        let store = TestStore(
            initialState: FormFeature.State(
                type: .post(
                    type: .new,
                    topicId: 0,
                    content: .simple("", [])
                )
            )
        ) {
            FormFeature()
        } withDependencies: {
            $0.apiClient.sendPost = { _ in
                throw NSError(domain: "network", code: 0)
            }
        }
        
        var editorState = FormEditorFeature.State(id: 0, flag: 1, defaultText: "")
        await store.send(.view(.onAppear)) {
            $0.rows = [.editor(editorState)]
            $0.focusedField = 0
        }
        
        #expect(store.state.isPublishButtonDisabled)
        
        await store.send(.rows(.element(id: 0, action: .editor(.binding(.set(\.text, "text")))))) {
            editorState.text = "text"
            $0.rows[id: 0] = .editor(editorState)
        }
                
        #expect(!store.state.isPublishButtonDisabled)
        
        await store.send(.view(.publishButtonTapped))

        await store.receive(\.internal.publishPost) {
            $0.isPublishing = true
        }
        
        await store.receive(\.internal.simplePostResponse) {
            $0.isPublishing = false
            $0.destination = .alert(.unknownError)
        }
    }
    
    // MARK: - Edit Post
    
    @Test func editPost() async throws {
        let store = TestStore(
            initialState: FormFeature.State(
                type: .post(
                    type: .edit(postId: 0),
                    topicId: 0,
                    content: .simple("some text", [])
                )
            )
        ) {
            FormFeature()
        } withDependencies: {
            $0.apiClient.editPost = { _ in
                return .success(PostSend(id: 0, topicId: 0, offset: 0))
            }
        }
        
        let editorState = FormEditorFeature.State(id: 0, flag: 1, defaultText: "some text")
        await store.send(.view(.onAppear)) {
            $0.rows = [.editor(editorState)]
            $0.focusedField = 0
        }
        
        #expect(store.state.inPostEditingMode)
        #expect(!store.state.isPublishButtonDisabled)
        
        await store.send(.binding(.set(\.isEditingReasonEnabled, true))) {
            $0.isEditingReasonEnabled = true
        }
        await store.send(.binding(.set(\.editReasonText, "reason"))) {
            $0.editReasonText = "reason"
        }
        
        await store.send(.view(.publishButtonTapped))
        
        await store.receive(\.internal.publishPost) {
            $0.isPublishing = true
        }
        await store.receive(\.internal.simplePostResponse)
        await store.receive(\.delegate.formSent)
    }
    
    // MARK: - Template Success
    
    @Test func templateSuccess() async throws {
        let store = TestStore(
            initialState: FormFeature.State(
                type: .post(
                    type: .new,
                    topicId: 0,
                    content: .template("")
                )
            )
        ) {
            FormFeature()
        } withDependencies: {
            $0.apiClient.getTemplate = { _, _ in
                return .releaser
            }
            $0.apiClient.sendTemplate = { _, _, _ in
                return .success(.post(.init(id: 0, topicId: 0, offset: 0)))
            }
        }
        
        let title = FormTitleFeature.State(id: 0, text: "[size=2][center][b][color=royalblue]Важно![/color][/b]\r\n[SIZE=1] [/SIZE]\r\nЕсли Вы используете инструмент впервые,  просьба ознакомиться с темой [url=\"https://4pda.to/forum/index.php?showtopic=950823\"][b]Релизер[/b][/url], а также [url=\"https://4pda.to/forum/index.php?act=announce&f=212&st=250\"][b]Правилами раздела и FAQ по созданию и обновлению тем[/b][/url][/center][/size]\r\n")
        var dropdown = FormDropdownFeature.State(
            id: 2,
            title: "Тип обновления",
            description: "Что публикуем?",
            flag: 1,
            options: [
                "Новая версия",
                "Beta",
                "Модификация",
                "Другое"
            ]
        )
        var text1 = FormTextFieldFeature.State(
            id: 3,
            title: "Версия",
            description: "Укажите версию. Например: 1.3.7",
            placeholder: "",
            flag: 1,
            defaultText: ""
        )
        var text2 = FormTextFieldFeature.State(
            id: 4,
            title: "Краткое описание",
            description: "Здесь можно указать: [I][U]источник, дату публикации, архитектуру, авторство, номер сборки, тип модификации[/U][/I] и так далее.\r\n[COLOR=red][I]Не повторяйте тут версию или название программы! Здесь запрещены ВВ-коды и ссылки.[/I][/COLOR]\r\nПример 1: Для ARM64 от 01/02/2022 из F-Droid\r\nПример 2: AdFree от ModMaker",
            placeholder: "",
            flag: 1,
            defaultText: ""
        )
        var editor = FormEditorFeature.State(
            id: 5,
            title: "Описание",
            description: "Введите дополнительную полезную информацию, например для:\r\n[b]\"Новая версия\"[/b] - список \"что нового\".\r\n[b]\"Модификация\"[/b] - \"на чем основано\", \"особенности\", \"обновлено\". ",
            placeholder: "",
            flag: 3,
            defaultText: ""
        )
        var uploadbox = FormUploadBoxFeature.State(
            id: 6,
            title: "Файлы",
            description: "",
            flag: 3,
            allowedExtensions: ["apk", "apks", "exe", "zip", "rar", "obb", "7z", "r00", "r01", "apkm", "ipa"]
        )
        
        await store.send(.view(.onAppear)) {
            $0.isFormLoading = true
        }
        
        await store.receive(\.internal.loadForm)
        
        await store.receive(\.internal.formResponse) {
            $0.isFormLoading = false
            $0.rows = [
                .title(title),
                .dropdown(dropdown),
                .textField(text1),
                .textField(text2),
                .editor(editor),
                .uploadBox(uploadbox)
            ]
        }
        
        await store.send(.rows(.element(id: 2, action: .dropdown(.view(.menuOptionSelected("Beta")))))) {
            dropdown.selectedOption = "Beta"
            $0.rows[id: 2] = .dropdown(dropdown)
        }
        
        await store.send(.rows(.element(id: 3, action: .textField(.binding(.set(\.text, "1.0.0")))))) {
            text1.text = "1.0.0"
            $0.rows[id: 3] = .textField(text1)
        }
        
        await store.send(.rows(.element(id: 4, action: .textField(.binding(.set(\.text, "Beta Update")))))) {
            text2.text = "Beta Update"
            $0.rows[id: 4] = .textField(text2)
        }
        
        await store.send(.rows(.element(id: 5, action: .editor(.binding(.set(\.text, "New beta update")))))) {
            editor.text = "New beta update"
            $0.rows[id: 5] = .editor(editor)
        }
        
        await store.send(.rows(.element(id: 6, action: .uploadBox(.view(.selectFilesButtonTapped))))) {
            uploadbox.destination = .confirmationDialog(
                ConfirmationDialogState<FormUploadBoxFeature.Destination.Dialog>(
                    title: { TextState(verbatim: "") },
                    actions: {
                        ButtonState(action: .gallery) {
                            TextState("Choose from Gallery", bundle: .module)
                        }
                        ButtonState(action: .files) {
                            TextState("Choose from Files", bundle: .module)
                        }
                    }
                )
            )
            $0.rows[id: 6] = .uploadBox(uploadbox)
        }
        
        #expect(store.state.isPublishButtonDisabled)
        
        let fileURL = try! saveBase64StringToDocuments(base64String: baseImage, filename: "base")
        
        await store.send(.rows(.element(id: 6, action: .uploadBox(.view(.fileImporterURLsRecieved([fileURL])))))) {
            uploadbox.files = [
                FormUploadBoxFeature.File(
                    id: 0,
                    name: "base",
                    type: .file,
                    data: try! Data(contentsOf: fileURL)
                )
            ]
            $0.rows[id: 6] = .uploadBox(uploadbox)
        }
        
        #expect(!store.state.isPublishButtonDisabled)
        
        await store.send(.view(.publishButtonTapped))
        
        await store.receive(\.internal.publishPost) {
            $0.isPublishing = true
        }
        
        await store.receive(\.internal.templateResponse)
        
        await store.receive(\.delegate.formSent)
    }
}

private func saveBase64StringToDocuments(base64String: String, filename: String) throws -> URL {
    guard let data = Data(base64Encoded: base64String) else {
        throw NSError(domain: "Base64Error", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid Base64"])
    }
    
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    let fileURL = documentsURL.appendingPathComponent(filename)
    
    try data.write(to: fileURL, options: .atomic)
    
    return fileURL
}

let baseImage = """
/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAIBAQEBAQIBAQECAgICAgQDAgICAgUEBAMEBgUGBgYFBgYGBwkIBgcJBwYGCAsICQoKCgoKBggLDAsKDAkKCgr/2wBDAQICAgICAgUDAwUKBwYHCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgr/wAARCAABAAEDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD9/KKKKAP/2Q==
"""
