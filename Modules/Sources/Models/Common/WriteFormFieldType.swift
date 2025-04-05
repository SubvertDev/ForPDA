//
//  WriteFormFieldType.swift
//  ForPDA
//
//  Created by Xialtal on 14.03.25.
//

public enum WriteFormFieldType: Sendable, Equatable, Hashable {
    case title(String)
    case text(FormField)
    case editor(FormField)
    case dropdown(FormField, _ options: [String])
    case uploadbox(FormField, _ extensions: [String])
    case checkboxList(FormField, _ options: [String])

    public struct FormField: Sendable, Equatable, Hashable {
        public let name: String
        public let description: String
        public let example: String
        public let flag: Int
        public let defaultValue: String
        
        public var isRequired: Bool {
            return flag & 1 != 0
        }
        
        public var isVisible: Bool {
            return flag & 2 != 0
        }
        
        public init(
            name: String,
            description: String,
            example: String,
            flag: Int,
            defaultValue: String
        ) {
            self.name = name
            self.description = description
            self.example = example
            self.flag = flag
            self.defaultValue = defaultValue
        }
    }
}

public extension WriteFormFieldType {
    static let mockTitle: WriteFormFieldType =
        .title("[b]This is absolute simple title[/b]")
    
    static let mockText: WriteFormFieldType = .text(
        FormField(
            name: "Topic name",
            description: "Enter topic name.",
            example: "Starting from For, ends with PDA",
            flag: 1,
            defaultValue: ""
        )
    )
    
    static let mockEditor: WriteFormFieldType = .editor(
        FormField(
            name: "Topic content",
            description: "This field contains topic [color=red]hat[/color] content.",
            example: "ForPDA Forever!",
            flag: 1,
            defaultValue: ""
        )
    )
    
    static let mockEditorSimple: WriteFormFieldType = .editor(
        FormField(
            name: "",
            description: "",
            example: "Post text...",
            flag: 0,
            defaultValue: ""
        )
    )
}
