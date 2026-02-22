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
        public let id: Int
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
            id: Int,
            name: String,
            description: String,
            example: String,
            flag: Int,
            defaultValue: String
        ) {
            self.id = id
            self.name = name
            self.description = description
            self.example = example
            self.flag = flag
            self.defaultValue = defaultValue
        }
    }
}

// MARK: - Mocks

public extension WriteFormFieldType {
    
    static let mockTitle: WriteFormFieldType =
        .title("This is an absolute [b]simple[/b] [i]title[/i]")
    
    static let mockText: WriteFormFieldType = .text(
        FormField(
            id: 0,
            name: "Topic name",
            description: "Enter topic name",
            example: "Starting from For, ends with PDA",
            flag: 1,
            defaultValue: ""
        )
    )
    
    static let mockEditor: WriteFormFieldType = .editor(
        FormField(
            id: 0,
            name: "Topic content",
            description: "This [B]field[/B] contains topic [color=red]hat[/color] content",
            example: "ForPDA Forever!",
            flag: 1,
            defaultValue: ""
        )
    )
    
    static let mockEditorSimple: WriteFormFieldType = .editor(
        FormField(
            id: 0,
            name: "",
            description: "",
            example: "Post text...",
            flag: 0,
            defaultValue: ""
        )
    )
    
    static let mockUploadBox: WriteFormFieldType = .uploadbox(
        .init(
            id: 0,
            name: "Device photos",
            description: "Upload device photos. Allowed formats JPG, GIF, PNG",
            example: "",
            flag: 1,
            defaultValue: ""
        ),
        ["jpg", "gif", "png"]
    )
}

extension Array where Element == WriteFormFieldType {
    public static let releaser: [WriteFormFieldType] = [
        .title("[size=2][center][b][color=royalblue]Важно![/color][/b]\r\n[SIZE=1] [/SIZE]\r\nЕсли Вы используете инструмент впервые,  просьба ознакомиться с темой [url=\"https://4pda.to/forum/index.php?showtopic=950823\"][b]Релизер[/b][/url], а также [url=\"https://4pda.to/forum/index.php?act=announce&f=212&st=250\"][b]Правилами раздела и FAQ по созданию и обновлению тем[/b][/url][/center][/size]\r\n"),
        .title(""),
        .dropdown(
            .init(
                id: 2,
                name: "Тип обновления",
                description: "Что публикуем?",
                example: "",
                flag: 1,
                defaultValue: ""
            ),
            [
                "Новая версия",
                "Beta",
                "Модификация",
                "Другое"
            ]
        ),
        .text(
            .init(
                id: 3,
                name: "Версия",
                description: "Укажите версию. Например: 1.3.7",
                example: "",
                flag: 1,
                defaultValue: ""
            )
        ),
        .text(
            .init(
                id: 4,
                name: "Краткое описание",
                description: "Здесь можно указать: [I][U]источник, дату публикации, архитектуру, авторство, номер сборки, тип модификации[/U][/I] и так далее.\r\n[COLOR=red][I]Не повторяйте тут версию или название программы! Здесь запрещены ВВ-коды и ссылки.[/I][/COLOR]\r\nПример 1: Для ARM64 от 01/02/2022 из F-Droid\r\nПример 2: AdFree от ModMaker",
                example: "",
                flag: 1,
                defaultValue: ""
            )
        ),
        .editor(
            .init(
                id: 5,
                name: "Описание",
                description: "Введите дополнительную полезную информацию, например для:\r\n[b]\"Новая версия\"[/b] - список \"что нового\".\r\n[b]\"Модификация\"[/b] - \"на чем основано\", \"особенности\", \"обновлено\". ",
                example: "",
                flag: 3,
                defaultValue: ""
            )
        ),
        .uploadbox(
            .init(
                id: 6,
                name: "Файлы",
                description: "",
                example: "",
                flag: 3,
                defaultValue: ""
            ),
            [
                "apk",
                "apks",
                "exe",
                "zip",
                "rar",
                "obb",
                "7z",
                "r00",
                "r01",
                "apkm",
                "ipa"
            ]
        )
    ]
}
