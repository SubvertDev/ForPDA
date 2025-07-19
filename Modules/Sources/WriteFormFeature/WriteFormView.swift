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
    @FocusState.Binding var isFocused: Bool
    
    let onUpdateContent: (String?) -> String // (String) -> Void?,
    var onUpdateSelection: ((Int, String, Bool) -> Void)?

    var body: some View {
        switch type {
        case .text(let content):
            Section {
                Field(
                    text: Binding(
                        get: { onUpdateContent(nil) },
                        set: { _ = onUpdateContent($0) }
                    ),
                    description: content.description,
                    guideText: content.example,
                    isFocused: $isFocused
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
                        get: { onUpdateContent(nil) },
                        set: { _ = onUpdateContent($0) }
                    ),
                    description: content.description,
                    guideText: content.example,
                    isEditor: true,
                    isFocused: $isFocused
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
                            ForEach(options, id: \.self) { option in
                                // TODO: Implement Button
                                Button {
                                    // callback
                                } label: { Text(option) }
                            }
                        } label: {
                            HStack {
                                Text(options[0]) // FIXME: Fix.
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
                    ForEach(options.indices, id: \.self) { index in
                        Toggle(isOn: Binding(
                            // FIXME: Now all checkboxes always false. Find the solution with getter.
                            get: { false },
                            set: { isSelected in
                                onUpdateSelection?(index, options[index], isSelected)
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
    
    @FocusState.Binding var isFocused: Bool
    
    var body: some View {
        VStack {
            Group {
                TextField(text: text, axis: .vertical) {
                    Text(guideText)
                        .font(.body)
                        .foregroundStyle(Color(.quaternaryLabel))
                }
                .focused($isFocused)
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
                    .onTapGesture {
                        isFocused = true
                    }
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
            isFocused = true
        }
    }
}

// MARK: - Field View Preview

@available(iOS 17, *)
#Preview("Field View") {
    @Previewable @FocusState var isFocused: Bool
    VStack {
        Spacer()
        
        Field(
            text: Binding( get: { "" }, set: { _ in } ),
            description: "Some basic description$",
            guideText: "Some guide text",
            isFocused: $isFocused
        )
        .bounceUpByLayerEffect(value: false)
        
        Color.white
    }
    .padding(.horizontal, 16)
}

// MARK: - Write Form Text Preview

@available(iOS 17, *)
#Preview("Write Form Text Preview") {
    @Previewable @FocusState var isFocused: Bool
    VStack {
        WriteFormView(type: .text(.init(
            name: "Topic name",
            description: "Set the topic name with some logic.",
            example: "Example: How I can do not love ForPDA?",
            flag: 1,
            defaultValue: ""
        )), isFocused: $isFocused, onUpdateContent: { _ in "" })
        
        Color.white
    }
    .padding(.horizontal, 16)
}

// MARK: - Write Form Title Preview

@available(iOS 17, *)
#Preview("Write Form Title Preview") {
    @Previewable @FocusState var isFocused: Bool
    VStack {
        WriteFormView(type: .title(
            "[b]Absolute simple.[/b]"
        ), isFocused: $isFocused, onUpdateContent: { _ in "" })
        
        Color.white
    }
    .padding(.horizontal, 16)
}

// MARK: - Write Form Editor Preview

@available(iOS 17, *)
#Preview("Write Form Editor Preview") {
    @Previewable @FocusState var isFocused: Bool
    VStack {
        WriteFormView(type: .editor(.init(
            name: "Topic name",
            description: "Set the topic name with some logic.",
            example: "Example: How I can do not love ForPDA?",
            flag: 1,
            defaultValue: ""
        )), isFocused: $isFocused, onUpdateContent: { _ in "" })
        
        Color.white
    }
    .padding(.horizontal, 16)
}

// MARK: - Write Form Dropdown Preview

@available(iOS 17, *)
#Preview("Write Form Dropdown Preview") {
    @Previewable @FocusState var isFocused: Bool
    VStack {
        WriteFormView(type: .dropdown(.init(
            name: "Device type",
            description: "Select device type.",
            example: "Example: Phone",
            flag: 1,
            defaultValue: ""
        ), ["Phone", "SmartWatch"]), isFocused: $isFocused, onUpdateContent: { _ in "" })
        
        Color.white
    }
    .padding(.horizontal, 16)
}

// MARK: - Write Form CheckBox Preview

@available(iOS 17, *)
#Preview("Write Form CheckBox Preview") {
    @Previewable @FocusState var isFocused: Bool
    VStack {
        WriteFormView(type: .checkboxList(.init(
            name: "",
            description: "",
            example: "",
            flag: 1,
            defaultValue: ""
        ), ["I accept all"]), isFocused: $isFocused, onUpdateContent: { _ in "" })
        
        Color.white
    }
    .padding(.horizontal, 16)
}

// MARK: - Write Form UploadBox Preview

@available(iOS 17, *)
#Preview("Write Form UploadBox Preview") {
    @Previewable @FocusState var isFocused: Bool
    VStack {
        WriteFormView(type: .uploadbox(.init(
            name: "Device photos",
            description: "Upload device photos. Allowed formats JPG, GIF, PNG",
            example: "",
            flag: 1,
            defaultValue: ""
        ), ["jpg", "gif", "png"]), isFocused: $isFocused, onUpdateContent: { _ in "" })
        
        Color.white
    }
    .padding(.horizontal, 16)
}
