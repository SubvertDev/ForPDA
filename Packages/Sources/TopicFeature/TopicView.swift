//
//  TopicView.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 07.11.2024.
//

import SwiftUI
import SharedUI
import NukeUI
import SFSafeSymbols
import Models

public struct TopicView: View {
        
    let type: TopicTypeUI
    let isTopLevel: Bool
    let attachments: [Post.Attachment]
    let textAlignment: NSTextAlignment?
    let onUrlTap: URLTapHandler?
    
    public init(
        type: TopicTypeUI,
        isTopLevel: Bool = true,
        attachments: [Post.Attachment] = [],
        alignment: NSTextAlignment? = nil,
        lineLimit: Int? = nil,
        onUrlTap: URLTapHandler? = nil
    ) {
        self.type = type
        self.isTopLevel = isTopLevel
        self.attachments = attachments
        self.textAlignment = alignment
        self.onUrlTap = onUrlTap
    }
    
    public var body: some View {
        switch type {
        case let .text(text):
            RichText(
                text: text,
                onUrlTap: onUrlTap,
                configuration: {
                    if let textAlignment {
                        ($0 as? UITextView)?.textAlignment = textAlignment
                    }
                }
            )
            
        case let .attachment(imageId):
            if let attachment = attachments.first(where: { $0.id == imageId }),
               let metadata = attachment.metadata,
               let url = URL(string: metadata.url) {
                LazyImage(url: url) { state in
                    Group {
                        if let image = state.image { image.resizable().scaledToFill() }
                    }
                    .skeleton(with: state.isLoading, shape: .rectangle)
                }
                .frame(
                    width: UIScreen.main.bounds.width / 1.5,
                    height: CGFloat(metadata.height) / CGFloat(metadata.width) * UIScreen.main.bounds.width / 1.5
                )
            }
            
        case let .image(url):
            LazyImage(url: url) { state in
                Group {
                    if let image = state.image { image.resizable().scaledToFill() }
                }
                .skeleton(with: state.isLoading, shape: .rectangle)
            }
            .frame(width: UIScreen.main.bounds.width / 1.5)
            
        case let .left(types):
            VStack(alignment: .leading) {
                ForEach(types, id: \.self) { type in
                    TopicView(type: type, attachments: attachments, alignment: .left, onUrlTap: onUrlTap)
                }
            }
            
        case let .center(types):
            VStack(alignment: .center) {
                ForEach(types, id: \.self) { type in
                    TopicView(type: type, attachments: attachments, alignment: .center, onUrlTap: onUrlTap)
                }
            }
            .frame(maxWidth: .infinity)
            
        case let .right(types):
            VStack(alignment: .trailing) {
                ForEach(types, id: \.self) { type in
                    TopicView(type: type, attachments: attachments, alignment: .right, onUrlTap: onUrlTap)
                }
            }
            
        case let .spoiler(types, info):
            SpoilerView(types: types, info: info, attachments: attachments, onUrlTap: onUrlTap)
            
        case let .quote(types, info):
            QuoteView(types: types, info: info, attachments: attachments, onUrlTap: onUrlTap)
            
        case let .code(type, info):
            CodeView(type: type, info: info, onUrlTap: onUrlTap)
            
        case let .list(types, _):
            VStack(spacing: 8) {
                ForEach(types, id: \.self) { type in
                    TopicView(type: type, isTopLevel: false, attachments: attachments)
                        .padding(.leading, isTopLevel ? 0 : 8)
                }
            }
            
        case let .notice(types, info):
            NoticeView(types: types, info: info, attachments: attachments, onUrlTap: onUrlTap)
            
        case let .bullet(types):
            HStack(alignment: .top, spacing: 6) {
                Image(systemSymbol: .circleFill)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.Labels.primary)
                    .frame(width: 6, height: 6)
                    .padding(.top, 7)
                
                VStack(spacing: 8) {
                    ForEach(types, id: \.self) { type in
                        TopicView(type: type, attachments: attachments)
                    }
                }
            }
        }
    }
}

// MARK: - Spoiler View

struct SpoilerView: View {
    
    @State private var isExpanded = false
    
    let types: [TopicTypeUI]
    let info: AttributedString?
    let attachments: [Post.Attachment]
    let onUrlTap: URLTapHandler?
    private let text: AttributedString
    
    private static var defaultAttributes: AttributeContainer {
        var container = AttributeContainer()
        container.foregroundColor = UIColor(Color.Labels.primary)
        container.font = UIFont.preferredFont(forTextStyle: .callout)
        return container
    }
    
    init(types: [TopicTypeUI], info: AttributedString?, attachments: [Post.Attachment], onUrlTap: URLTapHandler?) {
        self.types = types
        self.info = info
        self.attachments = attachments
        self.onUrlTap = onUrlTap
        
        var attrString = AttributedString("Спойлер\(info != nil ? ": " : "")")
        attrString.setAttributes(SpoilerView.defaultAttributes)
        if let info {
            attrString.foregroundColor = UIColor(Color.Labels.teritary)
            attrString.append(info)
        }
        self.text = attrString
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                RichText(text: text, onUrlTap: onUrlTap, configuration: {
                    ($0 as? UITextView)?.isSelectable = false
                })
                
                Spacer()
                
                Image(systemSymbol: isExpanded ? .chevronUp : .chevronDown)
                    .frame(width: 20, height: 20)
                    .foregroundStyle(Color.Labels.quaternary)
            }
            .padding(12)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                if isExpanded {
                    Rectangle()
                        .fill(Color.Separator.secondary)
                        .frame(height: 1)
                        .padding(.horizontal, 12)
                }
            }
            .onTapGesture {
                isExpanded.toggle()
            }
            
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(types, id: \.self) { type in
                        TopicView(type: type, attachments: attachments, onUrlTap: onUrlTap)
                    }
                }
                .padding(12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.Background.primary, strokeBorder: Color.Separator.secondary)
        )
        .animation(.default, value: isExpanded)
    }
}

// MARK: - Quote View

struct QuoteView: View {
    
    let types: [TopicTypeUI]
    let info: QuoteType?
    let attachments: [Post.Attachment]
    let onUrlTap: URLTapHandler?
    private let text: AttributedString
    private var date: String?
    
    private static var defaultAttributes: AttributeContainer {
        var container = AttributeContainer()
        container.foregroundColor = Color.Labels.primary
        container.font = .callout
        return container
    }
    
    init(types: [TopicTypeUI], info: QuoteType?, attachments: [Post.Attachment], onUrlTap: URLTapHandler?) {
        self.types = types
        self.info = info
        self.attachments = attachments
        self.onUrlTap = onUrlTap
        self.date = nil
        
        var text = AttributedString("Цитата\(info != nil ? ": " : "")")
        if let info {
            text.foregroundColor = Color.Labels.teritary
            text.font = .callout
            
            switch info {
            case .title(let string):
                var infoText = AttributedString(string)
                infoText.setAttributes(QuoteView.defaultAttributes)
                text.append(infoText)
            case .metadata(let metadata):
                var infoText = AttributedString(metadata.name)
                infoText.setAttributes(QuoteView.defaultAttributes)
                text.append(infoText)
                self.date = metadata.date
            }
        } else {
            text.setAttributes(QuoteView.defaultAttributes)
        }
        self.text = text
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text(text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if let date {
                    Spacer(minLength: 8)
                    
                    Text(date)
                        .foregroundStyle(Color.Labels.quaternary)
                        .font(.caption2)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 8)
            .padding(.horizontal, 12)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.Separator.secondary)
                    .frame(height: 1)
                    .padding(.horizontal, 12)
            }
            
            VStack(spacing: 8) {
                ForEach(types, id: \.self) { type in
                    TopicView(type: type, attachments: attachments, onUrlTap: onUrlTap)
                }
            }
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.Background.primary, strokeBorder: Color.Separator.secondary)
        )
    }
}

// MARK: - Code View

struct CodeView: View {
    
    @State private var isExpanded = false
    
    let type: TopicTypeUI
    let info: CodeType
    let onUrlTap: URLTapHandler?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Group {
                    switch info {
                    case .none:
                        Text("Код")
                            .foregroundStyle(Color.Labels.primary)
                        
                    case let .title(title):
                        HStack {
                            Text("Код: ")
                                .foregroundStyle(Color.Labels.teritary)
                            Text(title)
                                .foregroundStyle(Color.Labels.primary)
                        }
                    }
                }
                .font(.callout)
                
                Spacer()
                
                Image(systemSymbol: isExpanded ? .chevronUp : .chevronDown)
                    .font(.body)
                    .foregroundStyle(Color.Labels.quaternary)
                    .frame(width: 20, height: 20)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .bottom) {
                if isExpanded {
                    Rectangle()
                        .fill(Color.Separator.secondary)
                        .frame(height: 1)
                        .padding(.horizontal, 12)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isExpanded.toggle()
            }
            
            if isExpanded {
                if case .text = type {
                    TopicView(type: type)
                        .padding(12)
                } else {
                    fatalError("Non text type in CodeView")
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.Background.primary, strokeBorder: Color.Separator.secondary)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(Color.Main.greyAlpha)
                        .frame(width: 4)
                }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .animation(.default, value: isExpanded)
    }
}

// MARK: - Notice View

struct NoticeView: View {
    
    let types: [TopicTypeUI]
    let info: NoticeType
    let attachments: [Post.Attachment]
    let onUrlTap: URLTapHandler?
    
    var body: some View {
        VStack(spacing: 0) {
//            HStack(spacing: 0) {
//                Text(info.title)
//                    .font(.callout)
//                    .foregroundStyle(info.color)
//                    .frame(maxWidth: .infinity, alignment: .leading)
//            }
//            .padding([.top, .horizontal], 12)
//            .padding(.bottom, 8)
//            .overlay(alignment: .bottom) {
//                Rectangle()
//                    .fill(Color.Separator.secondary)
//                    .frame(height: 1)
//                    .padding(.horizontal, 12)
//            }
//            
            VStack(spacing: 8) {
                ForEach(types, id: \.self) { type in
                    TopicView(type: type, attachments: attachments, onUrlTap: onUrlTap)
                }
            }
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.Background.primary, strokeBorder: Color.Separator.secondary)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(info.color)
                        .frame(width: 4)
                }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Previews

#Preview("Code View") {
    let string = Array(repeating: "New Line!", count: 15).joined(separator: "\n")
    VStack {
        CodeView(
            type: .text(AttributedString(string)),
            info: .none,
            onUrlTap: nil
        )
        Color.white
    }
    .padding(.horizontal, 16)
}

#Preview("Notice View") {
    let string = Array(repeating: "Some text!", count: 15).joined(separator: "\n")
    VStack {
        NoticeView(
            types: [.text(AttributedString(string))],
            info: .moderator,
            attachments: [],
            onUrlTap: nil
        )
        Color.white
    }
    .padding(.horizontal, 16)
}

// TODO: Move to SharedUI
extension Shape {
    func fill<Fill: ShapeStyle, Stroke: ShapeStyle>(_ fillStyle: Fill, strokeBorder strokeStyle: Stroke, lineWidth: Double = 1) -> some View {
        self
            .stroke(strokeStyle, lineWidth: lineWidth)
            .background(self.fill(fillStyle))
    }
}

extension InsettableShape {
    func fill<Fill: ShapeStyle, Stroke: ShapeStyle>(_ fillStyle: Fill, strokeBorder strokeStyle: Stroke, lineWidth: Double = 1) -> some View {
        self
            .strokeBorder(strokeStyle, lineWidth: lineWidth)
            .background(self.fill(fillStyle))
    }
}
