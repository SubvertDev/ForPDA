//
//  WriteFormView.swift
//  ForPDA
//
//  Created by Xialtal on 14.03.25.
//

import SwiftUI
import ComposableArchitecture
import SharedUI
import Models
import BBBuilder

struct WriteFormView: View {
    
    let type: WriteFormFieldType
    
    let onUpdateContent: (_ fieldId: Int, _ data: FormContentData) -> Void
    let onFetchContent: (_ fieldId: Int) -> FormContentData?
    
    init(
        type: WriteFormFieldType,
        onUpdateContent: @escaping (Int, FormContentData) -> Void,
        onFetchContent: @escaping (Int) -> FormContentData?
    ) {
        self.type = type
        self.onUpdateContent = onUpdateContent
        self.onFetchContent = onFetchContent
    }

    var body: some View {
        switch type {
        case .text(let content):
            Section {
                Field(
                    text: Binding(
                        get: { getTextFieldContent(fieldId: content.id) },
                        set: { onUpdateContent(content.id, .text($0)) }
                    ),
                    description: content.description,
                    guideText: content.example
                )
            } header: {
                Header(title: content.name, required: content.isRequired)
            }
            
        case .title(let content):
            VStack(spacing: 6) {
                let nodes = BBBuilder.build(text: content, attachments: [])
                if case let .text(text) = nodes.first {
                    RichText(text: text)
                } else {
                    Text("Oops, error with loading title :(", bundle: .module)
                        .font(.subheadline)
                        .foregroundStyle(Color(.Labels.primary))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.Background.teritary))
            }
            
        case .editor(let content):
            Section {
                Field(
                    text: Binding(
                        get: { getTextFieldContent(fieldId: content.id) },
                        set: { onUpdateContent(content.id, .text($0)) }
                    ),
                    description: content.description,
                    guideText: content.example,
                    isEditor: true
                )
            } header: {
                if !content.name.isEmpty {
                    Header(title: content.name, required: content.isRequired)
                }
            }
            
        case .dropdown(let content, let options):
            Section {
                VStack {
                    HStack {
                        Menu {
                            ForEach(options.indices, id: \.hashValue) { index in
                                Button {
                                    onUpdateContent(content.id, .dropdown(index, options[index]))
                                } label: { Text(options[index]) }
                            }
                        } label: {
                            HStack {
                                Text(getDropdownSelectedName(fieldId: content.id))
                                    .foregroundStyle(Color(.Labels.primary))
                                    .padding(.leading, 16)
                                
                                Spacer()
                                
                                Image(systemSymbol: .chevronUpChevronDown)
                                    .foregroundStyle(Color(.Labels.teritary))
                                    .padding(.trailing, 11)
                            }
                            .padding(.vertical, 15)
                            .background(Color(.Background.teritary))
                            .cornerRadius(14)
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(.Separator.primary), lineWidth: 1)
                            }
                        }
                    }
                    .listRowBackground(Color(.Background.teritary))
                    
                    if !content.description.isEmpty {
                        DescriptionText(text: content.description)
                    }
                }
            } header: {
                Header(title: content.name, required: content.isRequired)
            }
            
        case .checkboxList(let content, let options):
            Section {
                VStack(spacing: 6) {
                    ForEach(options.indices, id: \.hashValue) { index in
                        Toggle(isOn: Binding(
                            get: { isCheckBoxSelected(fieldId: content.id, checkboxId: index) },
                            set: { isSelected in
                                onUpdateContent(content.id, .checkbox([index: isSelected]))
                            }
                        )) {
                            Text(options[index])
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .toggleStyle(CheckBox())
                        .padding(6)
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.Background.teritary))
                }
                
                if !content.description.isEmpty {
                    DescriptionText(text: content.description)
                }
            } header: {
                Header(title: content.name, required: content.isRequired)
            }
            
        case .uploadbox(let content, _ /* allowed extensions */):
            VStack(spacing: 6) {
                Header(title: content.name, required: content.isRequired)
                
                Button {
                    // TODO: Implement
                } label: {
                    VStack {
                        Image(systemSymbol: .docBadgePlus)
                            .font(.title)
                            .foregroundStyle(Color(.tintColor))
                            .frame(width: 48, height: 48)
                        
                        Text("Select files...", bundle: .module)
                            .font(.body)
                            .foregroundColor(Color(.Labels.quaternary))
                    }
                    .padding(.vertical, 15)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, minHeight: 144)
                    .background {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.Background.teritary))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                Color(.tintColor),
                                style: StrokeStyle(lineWidth: 1, dash: [8])
                            )
                    }
                }
                
                if !content.description.isEmpty {
                    DescriptionText(text: content.description)
                }
            }
        }
    }
    
    @ViewBuilder
    private func DescriptionText(text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(Color(.Labels.teritary))
            .textCase(nil)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 16)
    }

    // MARK: - Header
    
    @ViewBuilder
    private func Header(title: String, required: Bool) -> some View {
        HStack {
            Text(title)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(Color(.Labels.teritary))
                .textCase(nil)
                .overlay(alignment: .bottomTrailing) {
                    if required {
                        Text(verbatim: "*")
                            .font(.headline)
                            .offset(x: 8)
                            .foregroundStyle(.red)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Helpers

private extension WriteFormView {
    
    func getTextFieldContent(fieldId: Int) -> String {
        return if case .text(let content) = onFetchContent(fieldId) {
            content
        } else { "" }
    }
    
    func getDropdownSelectedName(fieldId: Int) -> String {
        return if case .dropdown(_, let name) = onFetchContent(fieldId) {
            name
        } else { "" }
    }
    
    func isCheckBoxSelected(fieldId: Int, checkboxId: Int) -> Bool {
        return if case .checkbox(let data) = onFetchContent(fieldId) {
            data[checkboxId] ?? false
        } else { false }
    }
}

// MARK: - CheckBox Toggle Style

struct CheckBox: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Button(action: {
                configuration.isOn.toggle()
            }, label: {
                if !configuration.isOn {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(.Separator.secondary), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .frame(width: 22, height: 22)
                        .overlay {
                            Image(systemSymbol: .checkmark)
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color(.white))
                        }
                }
            })
            
            configuration.label
        }
    }
}

// MARK: - Field View

struct Field: View {
    
    let text: Binding<String>
    let description: String
    let guideText: String
    var isEditor = false
    
    @FocusState private var focus: Bool
    
    var body: some View {
        VStack {
            Group {
                TextField(text: text, axis: .vertical) {
                    Text(guideText)
                        .font(.body)
                        .foregroundStyle(Color(.quaternaryLabel))
                }
                .focused($focus)
                .font(.body)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(Color(.Labels.primary))
                .frame(minHeight: isEditor ? 144 : nil, alignment: .top)
            }
            .padding(.vertical, 15)
            .padding(.horizontal, 12)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.Background.teritary))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color(.Separator.primary))
            }
            
            if !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(Color(.Labels.teritary))
                    .textCase(nil)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 16)
            }
        }
        .animation(.default, value: false)
        .onAppear {
            focus = true
        }
    }
}

// MARK: - Field View Preview

#Preview("Field View") {
    VStack {
        Spacer()
        
        Field(
            text: Binding( get: { "" }, set: { _ in } ),
            description: "Some basic description$",
            guideText: "Some guide text"
        )
        .bounceUpByLayerEffect(value: false)
        
        Color.white
    }
    .padding(.horizontal, 16)
}

// MARK: - Write Form Text Preview

#Preview("Write Form Text Preview") {
    VStack {
        WriteFormView(
            type: .text(
                .init(
                    id: 0,
                    name: "Topic name",
                    description: "Set the topic name with some logic.",
                    example: "Example: How I can do not love ForPDA?",
                    flag: 1,
                    defaultValue: ""
                )
            ),
            onUpdateContent: { _, _ in },
            onFetchContent: { _ in .text("Some basic text") }
        )
        
        Color.white
    }
    .padding(.horizontal, 16)
}

// MARK: - Write Form Title Preview

#Preview("Write Form Title Preview") {
    VStack {
        WriteFormView(
            type: .title("[b]Absolute simple.[/b]"),
            onUpdateContent: { _, _ in },
            onFetchContent: { _ in nil }
        )
        
        Color.white
    }
    .padding(.horizontal, 16)
}

// MARK: - Write Form Editor Preview

#Preview("Write Form Editor Preview") {
    VStack {
        WriteFormView(
            type: .editor(
                .init(
                    id: 0,
                    name: "Topic name",
                    description: "Set the topic name with some logic.",
                    example: "Example: How I can do not love ForPDA?",
                    flag: 1,
                    defaultValue: ""
                )
            ),
            onUpdateContent: { _, _ in },
            onFetchContent: { _ in .text("Some editor text") }
        )
        
        Color.white
    }
    .padding(.horizontal, 16)
}

// MARK: - Write Form Dropdown Preview

#Preview("Write Form Dropdown Preview") {
    VStack {
        WriteFormView(
            type: .dropdown(
                .init(
                    id: 0,
                    name: "Device type",
                    description: "Select device type.",
                    example: "Example: Phone",
                    flag: 1,
                    defaultValue: ""
                ),
                ["Phone", "SmartWatch"]
            ),
            onUpdateContent: { _, _ in },
            onFetchContent: { _ in .dropdown(0, "Phone") }
        )
        
        Color.white
    }
    .padding(.horizontal, 16)
}

// MARK: - Write Form CheckBox Preview

#Preview("Write Form CheckBox Preview") {
    VStack {
        WriteFormView(
            type: .checkboxList(
                .init(
                    id: 0,
                    name: "",
                    description: "",
                    example: "",
                    flag: 1,
                    defaultValue: ""
                ),
                ["I accept all"]
            ),
            onUpdateContent: { _, _ in },
            onFetchContent: { _ in .checkbox([0: true]) }
        )
        
        Color.white
    }
    .padding(.horizontal, 16)
}

// MARK: - Write Form UploadBox Preview

#Preview("Write Form UploadBox Preview") {
    VStack {
        WriteFormView(
            type: .uploadbox(
                .init(
                    id: 0,
                    name: "Device photos",
                    description: "Upload device photos. Allowed formats JPG, GIF, PNG",
                    example: "",
                    flag: 1,
                    defaultValue: ""
                ),
                ["jpg", "gif", "png"]
            ),
            onUpdateContent: { _, _ in },
            onFetchContent: { _ in .uploadbox([]) }
        )
        
        Color.white
    }
    .padding(.horizontal, 16)
}
