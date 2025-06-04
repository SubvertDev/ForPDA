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
import Sharing
import Dependencies
import CacheClient

public typealias ImageTapHandler = (URL) -> Void

public struct TopicView: View {
    
    let type: TopicTypeUI
    let nestLevel: Int
    let attachments: [Post.Attachment]
    let textAlignment: NSTextAlignment?
    let onUrlTap: URLTapHandler?
    let onImageTap: ImageTapHandler?
    
    public init(
        type: TopicTypeUI,
        nestLevel: Int = 1,
        attachments: [Post.Attachment] = [],
        alignment: NSTextAlignment? = nil,
        lineLimit: Int? = nil,
        onUrlTap: URLTapHandler? = nil,
        onImageTap: ImageTapHandler? = nil
    ) {
        self.type = type
        self.nestLevel = nestLevel
        self.attachments = attachments
        self.textAlignment = alignment
        self.onUrlTap = onUrlTap
        self.onImageTap = onImageTap
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
            
        case let .attachment(attachment):            
            let metadata = attachment.metadata!
            
            let padding: CGFloat = CGFloat(((nestLevel - 1) * 12) + 16) * 2
            let availableWidth = UIScreen.main.bounds.width - padding
            let ratioWH = CGFloat(metadata.width) / CGFloat(metadata.height)
            let scaleFactor = availableWidth / CGFloat(metadata.width)
            let isWidthMoreThanAvailable = scaleFactor < 1

            let width = isWidthMoreThanAvailable ? availableWidth : CGFloat(metadata.width)
            let height = width / ratioWH
            
            LazyImage(url: metadata.url) { state in
                if let container = state.imageContainer {
                    if container.type == .gif {
                        GifView(url: metadata.url)
                    } else {
                        Group {
                            if let image = state.image { image.resizable().scaledToFit() }
                        }
                        .skeleton(with: state.isLoading, shape: .rectangle)
                    }
                }
            }
            .frame(width: width, height: height)
            .onTapGesture {
                onImageTap?(metadata.url)
            }
            
        case let .image(url):
            LazyImage(url: url) { state in
                Group {
                    if let image = state.image { image.resizable().scaledToFill() }
                }
                .skeleton(with: state.isLoading, shape: .rectangle)
            }
            .onTapGesture {
                onImageTap?(url)
            }
            
        case let .left(types):
            VStack(alignment: .leading) {
                ForEach(types, id: \.self) { type in
                    TopicView(
                        type: type,
                        nestLevel: nestLevel + 1,
                        attachments: attachments,
                        alignment: .left,
                        onUrlTap: onUrlTap,
                        onImageTap: onImageTap
                    )
                }
            }
            
        case let .center(types):
            VStack(alignment: .center) {
                ForEach(types, id: \.self) { type in
                    TopicView(
                        type: type,
                        nestLevel: nestLevel + 1,
                        attachments: attachments,
                        alignment: .center,
                        onUrlTap: onUrlTap,
                        onImageTap: onImageTap
                    )
                }
            }
            .frame(maxWidth: .infinity)
            
        case let .right(types):
            VStack(alignment: .trailing) {
                ForEach(types, id: \.self) { type in
                    TopicView(
                        type: type,
                        nestLevel: nestLevel + 1,
                        attachments: attachments,
                        alignment: .right,
                        onUrlTap: onUrlTap,
                        onImageTap: onImageTap
                    )
                }
            }
            
        case let .spoiler(types, info):
            SpoilerView(
                types: types,
                nestLevel: nestLevel,
                info: info,
                attachments: attachments,
                onUrlTap: onUrlTap,
                onImageTap: onImageTap
            )
            
        case let .quote(types, info):
            QuoteView(
                types: types,
                nestLevel: nestLevel,
                info: info,
                attachments: attachments,
                onUrlTap: onUrlTap,
                onImageTap: onImageTap
            )
            
        case let .code(type, info):
            CodeView(
                type: type,
                nestLevel: nestLevel,
                info: info,
                onUrlTap: onUrlTap,
                onImageTap: onImageTap
            )
            
        case let .hide(types, info):
            HideView(
                types: types,
                nestLevel: nestLevel,
                info: info,
                attachments: attachments,
                onUrlTap: onUrlTap,
                onImageTap: onImageTap
            )
            
        case let .list(types, _):
            VStack(spacing: 8) {
                ForEach(types, id: \.self) { type in
                    TopicView(
                        type: type,
                        nestLevel: nestLevel + 1,
                        attachments: attachments,
                        onUrlTap: onUrlTap,
                        onImageTap: onImageTap
                    )
                    .padding(.leading, nestLevel == 1 ? 0 : 8)
                }
            }
            
        case let .notice(types, info):
            NoticeView(
                types: types,
                nestLevel: nestLevel + 1,
                info: info,
                attachments: attachments,
                onUrlTap: onUrlTap,
                onImageTap: onImageTap
            )
            
        case let .bullet(types):
            HStack(alignment: .top, spacing: 6) {
                Image(systemSymbol: .circleFill)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color(.Labels.primary))
                    .frame(width: 6, height: 6)
                    .padding(.top, 7)
                
                VStack(spacing: 8) {
                    ForEach(types, id: \.self) { type in
                        TopicView(
                            type: type,
                            attachments: attachments,
                            onUrlTap: onUrlTap,
                            onImageTap: onImageTap
                        )
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
    let nestLevel: Int
    let info: AttributedString?
    let attachments: [Post.Attachment]
    let onUrlTap: URLTapHandler?
    let onImageTap: ImageTapHandler?
    private let text: AttributedString
    
    private static var defaultAttributes: AttributeContainer {
        var container = AttributeContainer()
        container.foregroundColor = UIColor(Color(.Labels.primary))
        container.font = UIFont.preferredFont(forTextStyle: .callout)
        return container
    }
    
    init(
        types: [TopicTypeUI],
        nestLevel: Int,
        info: AttributedString?,
        attachments: [Post.Attachment],
        onUrlTap: URLTapHandler?,
        onImageTap: ImageTapHandler?
    ) {
        self.types = types
        self.nestLevel = nestLevel
        self.info = info
        self.attachments = attachments
        self.onUrlTap = onUrlTap
        self.onImageTap = onImageTap
        
        var attrString = AttributedString("Спойлер\(info != nil ? ": " : "")")
        attrString.setAttributes(SpoilerView.defaultAttributes)
        if let info {
            attrString.foregroundColor = UIColor(Color(.Labels.teritary))
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
                    .foregroundStyle(Color(.Labels.quaternary))
            }
            .padding(12)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                if isExpanded {
                    Rectangle()
                        .fill(Color(.Separator.secondary))
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
                        TopicView(
                            type: type,
                            nestLevel: nestLevel + 1,
                            attachments: attachments,
                            onUrlTap: onUrlTap,
                            onImageTap: onImageTap
                        )
                    }
                }
                .padding(12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.Background.primary), strokeBorder: Color(.Separator.secondary))
        )
        .animation(.default, value: isExpanded)
    }
}

// MARK: - Quote View

struct QuoteView: View {
    
    let types: [TopicTypeUI]
    let nestLevel: Int
    let info: QuoteType?
    let attachments: [Post.Attachment]
    let onUrlTap: URLTapHandler?
    let onImageTap: ImageTapHandler?
    private let text: AttributedString
    private var date: String?
    
    private static var defaultAttributes: AttributeContainer {
        var container = AttributeContainer()
        container.foregroundColor = Color(.Labels.primary)
        container.font = .callout
        return container
    }
    
    init(
        types: [TopicTypeUI],
        nestLevel: Int,
        info: QuoteType?,
        attachments: [Post.Attachment],
        onUrlTap: URLTapHandler?,
        onImageTap: ImageTapHandler?
    ) {
        self.types = types
        self.nestLevel = nestLevel
        self.info = info
        self.attachments = attachments
        self.onUrlTap = onUrlTap
        self.date = nil
        self.onImageTap = onImageTap
        
        var text = AttributedString("Цитата\(info != nil ? ": " : "")")
        if let info {
            text.foregroundColor = Color(.Labels.teritary)
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
                        .foregroundStyle(Color(.Labels.quaternary))
                        .font(.caption2)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 8)
            .padding(.horizontal, 12)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color(.Separator.secondary))
                    .frame(height: 1)
                    .padding(.horizontal, 12)
            }
            
            VStack(spacing: 8) {
                ForEach(types, id: \.self) { type in
                    TopicView(
                        type: type,
                        nestLevel: nestLevel + 1,
                        attachments: attachments,
                        onUrlTap: onUrlTap,
                        onImageTap: onImageTap
                    )
                }
            }
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.Background.primary), strokeBorder: Color(.Separator.secondary))
        )
    }
}

// MARK: - Code View

struct CodeView: View {
    
    @State private var isExpanded = false
    
    let type: TopicTypeUI
    let nestLevel: Int
    let info: CodeType
    let onUrlTap: URLTapHandler?
    let onImageTap: ImageTapHandler?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Group {
                    switch info {
                    case .none:
                        Text("Code", bundle: .module)
                            .foregroundStyle(Color(.Labels.primary))
                        
                    case let .title(title):
                        HStack {
                            Text("Code: ", bundle: .module)
                                .foregroundStyle(Color(.Labels.teritary))
                            Text(title)
                                .foregroundStyle(Color(.Labels.primary))
                        }
                    }
                }
                .font(.callout)
                
                Spacer()
                
                Image(systemSymbol: isExpanded ? .chevronUp : .chevronDown)
                    .font(.body)
                    .foregroundStyle(Color(.Labels.quaternary))
                    .frame(width: 20, height: 20)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .bottom) {
                if isExpanded {
                    Rectangle()
                        .fill(Color(.Separator.secondary))
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
                    TopicView(
                        type: type,
                        onUrlTap: onUrlTap,
                        onImageTap: onImageTap
                    )
                    .padding(12)
                } else {
                    fatalError("Non text type in CodeView")
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.Background.primary), strokeBorder: Color(.Separator.secondary))
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.Main.greyAlpha))
                        .frame(width: 4)
                }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .animation(.default, value: isExpanded)
    }
}

// MARK: - Hide View

struct HideView: View {
    
    let types: [TopicTypeUI]
    let nestLevel: Int
    let info: Int?
    let attachments: [Post.Attachment]
    let onUrlTap: URLTapHandler?
    let onImageTap: ImageTapHandler?
    
    @State var isShown: Bool
    @State private var shouldLoadUser: Int?
    
    init(
        types: [TopicTypeUI],
        nestLevel: Int,
        info: Int?,
        attachments: [Post.Attachment],
        onUrlTap: URLTapHandler?,
        onImageTap: ImageTapHandler?
    ) {
        self.types = types
        self.nestLevel = nestLevel
        self.info = info
        self.attachments = attachments
        self.onUrlTap = onUrlTap
        self.onImageTap = onImageTap
        
        @Shared(.userSession) var userSession: UserSession?
        if let userSession = userSession.wrapped {
            if info != nil {
                self._isShown = State(initialValue: false)
                self._shouldLoadUser = State(initialValue: userSession.userId)  //userSession.userId
            } else {
                self._isShown = State(initialValue: true)
            }
        } else {
            self._isShown = State(initialValue: false)
        }
    }
    
    var body: some View {
        Group {
            if isShown {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Text("Hidden text", bundle: .module)
                            .foregroundStyle(Color(.Labels.primary))
                            .font(.callout)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(12)
                    .overlay(alignment: .bottom) {
                        if isShown {
                            Rectangle()
                                .fill(Color(.Separator.secondary))
                                .frame(height: 1)
                                .padding(.horizontal, 12)
                        }
                    }
                    
                    if isShown {
                        VStack(spacing: 8) {
                            ForEach(types, id: \.self) { type in
                                TopicView(type: type, nestLevel: nestLevel + 1, attachments: attachments, onUrlTap: onUrlTap)
                            }
                        }
                        .padding(12)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.Background.primary), strokeBorder: Color(.Separator.secondary))
                )
            }
        }
        .animation(.default, value: isShown)
        .task {
            #warning("What is happening here?")
            @Dependency(\.cacheClient) var cache
            if let userId = shouldLoadUser, let info {
                if let currentUser = await cache.getUser(userId) {
                    if currentUser.replies >= info {
                        isShown = true
                    }
                }
            }
        }
    }
}

// MARK: - Notice View

struct NoticeView: View {
    
    let types: [TopicTypeUI]
    let nestLevel: Int
    let info: NoticeType
    let attachments: [Post.Attachment]
    let onUrlTap: URLTapHandler?
    let onImageTap: ImageTapHandler?
    
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
//                    .fill(Color(.Separator.secondary))
//                    .frame(height: 1)
//                    .padding(.horizontal, 12)
//            }
//            
            VStack(spacing: 8) {
                ForEach(types, id: \.self) { type in
                    TopicView(
                        type: type,
                        nestLevel: nestLevel + 1,
                        attachments: attachments,
                        onUrlTap: onUrlTap,
                        onImageTap: onImageTap
                    )
                }
            }
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.Background.primary), strokeBorder: Color(.Separator.secondary))
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(info.color)
                        .frame(width: 4)
                }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Extensions

public extension NoticeType {
    var color: Color {
        switch self {
        case .curator:   return Color(.Main.green)
        case .moderator: return Color(.Theme.primary)
        case .admin:     return Color(.Main.red)
        }
    }
}

// MARK: - Previews

#Preview("Code View") {
    let string = Array(repeating: "New Line!", count: 15).joined(separator: "\n")
    VStack {
        CodeView(
            type: .text(AttributedString(string)),
            nestLevel: 1,
            info: .none,
            onUrlTap: nil,
            onImageTap: nil
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
            nestLevel: 1,
            info: .moderator,
            attachments: [],
            onUrlTap: nil,
            onImageTap: nil
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
