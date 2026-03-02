//
//  FormFieldType.swift
//  ForPDA
//
//  Created by Xialtal on 14.03.25.
//

public enum FormFieldType: Sendable, Equatable, Hashable {
    case title(String)
    case text(FormField, maxLenght: Int?)
    case editor(FormField)
    case dropdown(FormField, _ options: [String])
    case uploadbox(FormField, _ extensions: [String])
    case checkboxList(FormField, _ options: [String])

    public struct FormField: Sendable, Equatable, Hashable {
        public let id: Int
        public let name: String
        public let description: String
        public let example: String
        public let flag: FormFlag
        public let defaultValue: String
        
        public init(
            id: Int,
            name: String,
            description: String,
            example: String,
            flag: FormFlag,
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

public extension FormFieldType {
    
    static let mockTitle: FormFieldType =
        .title("This is an absolute [b]simple[/b] [i]title[/i]")
    
    static let mockRequiredText: FormFieldType = .text(
        FormField(
            id: 0,
            name: "Topic name",
            description: "Enter topic name",
            example: "Starting from For, ends with PDA",
            flag: .required,
            defaultValue: ""
        ),
        maxLenght: 255
    )
    
    static let mockRequiredEditor: FormFieldType = .editor(
        FormField(
            id: 0,
            name: "Topic content",
            description: "This [B]field[/B] contains topic [color=red]hat[/color] content",
            example: "ForPDA Forever!",
            flag: .required,
            defaultValue: ""
        )
    )
    
    static let mockEditor: FormFieldType = .editor(
        FormField(
            id: 0,
            name: "",
            description: "",
            example: "Post text...",
            flag: [],
            defaultValue: ""
        )
    )
    
    static let mockUploadBox: FormFieldType = .uploadbox(
        .init(
            id: 0,
            name: "Device photos",
            description: "Upload device photos. Allowed formats JPG, GIF, PNG",
            example: "",
            flag: .required,
            defaultValue: ""
        ),
        ["jpg", "gif", "png"]
    )
}

extension Array where Element == FormFieldType {
    public static let releaser: [FormFieldType] = [
        .title("[size=2][center][b][color=royalblue]Важно![/color][/b]\r\n[SIZE=1] [/SIZE]\r\nЕсли Вы используете инструмент впервые,  просьба ознакомиться с темой [url=\"https://4pda.to/forum/index.php?showtopic=950823\"][b]Релизер[/b][/url], а также [url=\"https://4pda.to/forum/index.php?act=announce&f=212&st=250\"][b]Правилами раздела и FAQ по созданию и обновлению тем[/b][/url][/center][/size]\r\n"),
        .title(""),
        .dropdown(
            .init(
                id: 2,
                name: "Тип обновления",
                description: "Что публикуем?",
                example: "",
                flag: .required,
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
                flag: .required,
                defaultValue: ""
            ),
            maxLenght: 255
        ),
        .text(
            .init(
                id: 4,
                name: "Краткое описание",
                description: "Здесь можно указать: [I][U]источник, дату публикации, архитектуру, авторство, номер сборки, тип модификации[/U][/I] и так далее.\r\n[COLOR=red][I]Не повторяйте тут версию или название программы! Здесь запрещены ВВ-коды и ссылки.[/I][/COLOR]\r\nПример 1: Для ARM64 от 01/02/2022 из F-Droid\r\nПример 2: AdFree от ModMaker",
                example: "",
                flag: .required,
                defaultValue: ""
            ),
            maxLenght: nil
        ),
        .editor(
            .init(
                id: 5,
                name: "Описание",
                description: "Введите дополнительную полезную информацию, например для:\r\n[b]\"Новая версия\"[/b] - список \"что нового\".\r\n[b]\"Модификация\"[/b] - \"на чем основано\", \"особенности\", \"обновлено\". ",
                example: "",
                flag: [.required, .uploadable],
                defaultValue: ""
            )
        ),
        .uploadbox(
            .init(
                id: 6,
                name: "Файлы",
                description: "",
                example: "",
                flag: [.required, .uploadable],
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
