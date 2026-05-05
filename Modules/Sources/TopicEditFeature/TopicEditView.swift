//
//  TopicEditView.swift
//  ForPDA
//
//  Created by Xialtal on 29.03.26.
//

import SwiftUI
import ComposableArchitecture
import SharedUI
import Models

@ViewAction(for: TopicEditFeature.self)
public struct TopicEditView: View {
    
    @Perception.Bindable public var store: StoreOf<TopicEditFeature>
    @FocusState private var focus: TopicEditFeature.State.Field?
    @Environment(\.tintColor) private var tintColor
    
    public init(store: StoreOf<TopicEditFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ScrollView(.vertical) {
                VStack(spacing: 28) {
                    Field(
                        title: "Topic header",
                        content: $store.title,
                        placeholder: LocalizedStringResource("Input...", bundle: .module),
                        focusEqual: .title,
                        characterLimit: 255
                    )
                    .disabled(!store.canModerate)
                    
                    Field(
                        title: "Topic description",
                        content: $store.description,
                        placeholder: LocalizedStringResource("Input...", bundle: .module),
                        focusEqual: .description,
                        characterLimit: 255
                    )
                    .disabled(!store.canModerate)
                    
                    if store.supportsPoll {
                        Poll()
                    }
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
            .navigationTitle(Text("Topic Edit", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                SaveButton()
            }
            .onTapGesture {
                focus = nil
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        send(.cancelButtonTapped)
                    } label: {
                        if isLiquidGlass {
                            Image(systemSymbol: .xmark)
                        } else {
                            Text("Cancel", bundle: .module)
                        }
                    }
                    .tint(tintColor)
                    .disabled(store.isSending)
                }
            }
            .background(Color(.Background.primary))
            .disabled(store.isSending)
            .animation(.default, value: store.isSending)
            .bind($store.focus, to: $focus)
            .onAppear {
                send(.onAppear)
            }
        }
    }
    
    // MARK: - Save Button
    
    @ViewBuilder
    private func SaveButton() -> some View {
        Button {
           // send(.publishButtonTapped)
        } label: {
            if store.isSending {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity)
                    .padding(8)
            } else {
                Text("Save", bundle: .module)
                    .frame(maxWidth: .infinity)
                    .padding(8)
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(tintColor)
        //.disabled(store.isSaveButtonDisabled)
        .frame(height: 48)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(.Background.primary))
    }
    
    // MARK: - Poll
    
    private func Poll() -> some View {
        WithPerceptionTracking {
            VStack {
                HStack(spacing: 0) {
                    Text("Enable poll", bundle: .module)
                        .foregroundStyle(Color(.Labels.teritary))
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Toggle(String(""), isOn: $store.isPollEnabled)
                        .labelsHidden()
                        .tint(tintColor)
                }
                .padding(.horizontal, 2)
                
                if store.isPollEnabled {
                    VStack(spacing: 16) {
                        Field(
                            content: $store.draftPoll.name,
                            placeholder: LocalizedStringResource("Input poll name", bundle: .module),
                            focusEqual: .pollName
                        )
                        
                        ForEach(store.draftPoll.options) { question in
                            WithPerceptionTracking {
                                // We use this solution with binding, because otherwise, on iOS 17+,
                                // when deleting a question, error "Index out of range" appears
                                // due to the fact that "multiselection Toggle" calling an already deleted question
                                let question = store.draftPoll.options.first { $0.id == question.id } ?? question
                                PollQuestion(
                                    question: Binding(
                                        get: { question },
                                        set: { newValue in
                                            send(.updateQuestion(question.id, newValue))
                                        }
                                    )
                                )
                            }
                        }
                        
                        AddPollElementButton(title: "Question") {
                            send(.addQuestionButtonTapped)
                        }
                    }
                }
            }
        }
        .animation(.default, value: store.isPollEnabled)
    }
    
    // MARK: - Poll Question
    
    @ViewBuilder
    private func PollQuestion(question: Binding<Topic.Poll.Option>) -> some View {
        VStack(spacing: 10) {
            Field(
                title: "Question",
                content: question.name,
                placeholder: LocalizedStringResource("Input question", bundle: .module),
                focusEqual: .pollQuestion(question.wrappedValue.id),
                action: {
                    RemovePollElementButton {
                        send(.removeQuestionButtonTapped(question.wrappedValue.id))
                    }
                }
            )
            
            HStack(spacing: 0) {
                Toggle(String(""), isOn: question.several)
                    .labelsHidden()
                    .tint(tintColor)
                    .padding(.trailing, 8)
                
                Text("Enable multi-selection", bundle: .module)
                    .foregroundStyle(Color(.Labels.teritary))
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.bottom, 12)
            
            PollAnswers(questionId: question.wrappedValue.id, question.choices)
            
            AddPollElementButton(title: "Answer") {
                send(.addAnswerButtonTapped(questionId: question.wrappedValue.id))
            }
        }
        .padding(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.Separator.secondary), lineWidth: 1)
        )
    }
    
    // MARK: - Poll Answer
    
    @ViewBuilder
    private func PollAnswers(questionId: Int, _ answers: Binding<[Topic.Poll.Choice]>) -> some View {
        VStack(spacing: 8) {
            Header(title: "Answers")
            
            ForEach(answers) { answer in
                WithPerceptionTracking {
                    HStack(spacing: 8) {
                        Field(
                            type: .singleLine(numeric: false),
                            content: answer.name,
                            placeholder: LocalizedStringResource("Input answer", bundle: .module),
                            focusEqual: .pollAnswer(questionId: questionId, answer.wrappedValue.id),
                            action: {
                                if !store.canModerate {
                                    RemovePollElementButton {
                                        send(.removeAnswerButtonTapped(questionId: questionId, answer.wrappedValue.id))
                                    }
                                }
                            }
                        )
                        
                        if store.canModerate {
                            Field(
                                type: .singleLine(numeric: true),
                                content: Binding(get: { String(answer.votes.wrappedValue) }, set: { newValue in
                                    send(.updateAnswerVotes(questionId: questionId, answerId: answer.wrappedValue.id, newValue))
                                }),
                                placeholder: LocalizedStringResource(stringLiteral: String(answer.votes.wrappedValue)),
                                focusEqual: .pollAnswerVote(questionId: questionId, answer.wrappedValue.id),
                                characterLimit: 7,
                                action: {
                                    RemovePollElementButton {
                                        send(.removeAnswerButtonTapped(questionId: questionId, answer.wrappedValue.id))
                                    }
                                }
                            )
                            .frame(width: 120)
                        }
                        
                    }
                }
            }
        }
    }
    
    // MARK: - Add Poll Element Button
    
    @ViewBuilder
    private func AddPollElementButton(
        title: LocalizedStringKey,
        action: @escaping () -> ()
    ) -> some View {
        Button {
            action()
        } label: {
            HStack {
                Image(systemSymbol: .plus)
                
                Text(title, bundle: .module)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .tint(tintColor)
        .buttonStyle(.bordered)
    }
    
    // MARK: - Remove Poll Element Button
    
    @ViewBuilder
    private func RemovePollElementButton(action: @escaping () -> ()) -> some View {
        Button {
            action()
        } label: {
            Image(systemSymbol: .trash)
                .foregroundStyle(.red)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Field
    
    enum FieldType {
        case singleLine(numeric: Bool)
        case full
    }
    
    private func Field<Action: View>(
        type: FieldType = .full,
        title: LocalizedStringKey? = nil,
        content: Binding<String>,
        placeholder: LocalizedStringResource,
        focusEqual: TopicEditFeature.State.Field,
        characterLimit: Int? = nil,
        @ViewBuilder action: @escaping () -> Action = { EmptyView() }
    ) -> some View {
        VStack(spacing: 6) {
            if let title = title {
                Header(title: title)
            }
            
            HStack {
                switch type {
                case .singleLine(let numeric):
                    SharedUI.SingleLineField(
                        content: content,
                        placeholder: placeholder,
                        focusEqual: focusEqual,
                        focus: $focus,
                        keyboardType: numeric ? .numberPad : .default,
                        characterLimit: characterLimit
                    )
                case .full:
                    SharedUI.Field(
                        content: content,
                        placeholder: placeholder,
                        focusEqual: focusEqual,
                        focus: $focus,
                        characterLimit: characterLimit
                    )
                }
                
                action()
            }
        }
    }
    
    private func Header(title: LocalizedStringKey) -> some View {
        Text(title, bundle: .module)
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(Color(.Labels.teritary))
            .textCase(nil)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        TopicEditView(store: Store(
            initialState: TopicEditFeature.State(
                id: 0,
                flag: .canModerate,
                title: "Test Title",
                description: "Description",
                poll: .mock,
                supportsPoll: true
            )
        ) {
            TopicEditFeature()
        })
    }
}
