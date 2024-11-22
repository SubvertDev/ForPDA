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
import RichTextKit

struct TopicView: View {
        
    let type: TopicType
    let attachments: [Post.Attachment]
    let textAlignment: NSTextAlignment?
    
    init(
        type: TopicType,
        attachments: [Post.Attachment],
        alignment: NSTextAlignment? = nil
    ) {
        self.type = type
        self.attachments = attachments
        self.textAlignment = alignment
    }
    
    var body: some View {
        switch type {
        case .error:
            Text("Whoops, something went wrong while parsing this post :(", bundle: .module)
                .foregroundStyle(.background)
                .padding(16)
                .background(Color(uiColor: .label))
            
        case let .text(text):
            RichText(text: text) {
                if let textAlignment {
                    ($0 as? UITextView)?.textAlignment = textAlignment
                }
            }
            
        case let .image(imageId):
            if let attachment = attachments.first(where: { $0.id == imageId }),
               let metadata = attachment.metadata,
               let url = URL(string: metadata.url) {
                LazyImage(url: url) { state in
                    if let image = state.image { image.resizable().scaledToFill() }
                }
                .frame(
                    width: UIScreen.main.bounds.width / 2,
                    height: CGFloat(metadata.height) / CGFloat(metadata.width) * UIScreen.main.bounds.width / 2
                )
            }
            
        case let .center(types):
            VStack(alignment: .center) {
                ForEach(types, id: \.self) { type in
                    TopicView(type: type, attachments: attachments, alignment: .center)
                }
            }
            .frame(maxWidth: .infinity)
            
        case let .right(types):
            VStack(alignment: .trailing) {
                ForEach(types, id: \.self) { type in
                    TopicView(type: type, attachments: attachments, alignment: .right)
                }
            }
            
        case let .spoiler(types, info):
            SpoilerView(types: types, info: info, attachments: attachments)
            
        case let .quote(text, type):
            QuoteView(text: text, type: type)
            
        case let .mergetime(date):
            RichText(text: "Добавлено: \(date.formatted())".asNSAttributedString(font: .footnote))
        }
    }
}

// MARK: - Quote View

struct QuoteView: View {
    
    let text: NSAttributedString
    let type: QuoteType
    
    var body: some View {
        VStack(spacing: 8) {
            Group {
                switch type {
                case .none:
                    Text("Quote", bundle: .module)
                    
                case let .title(title):
                    Text("Quote: \(title)", bundle: .module)
                    
                case let .user(user):
                    Text("Quote: \(user.name) @ \(user.date)", bundle: .module)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.Main.primaryAlpha)
            
            RichText(text: text)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
        }
        .border(Color.Main.primaryAlpha)
    }
}

// MARK: - Spoiler View

struct SpoilerView: View {
    
    @State private var isExpanded = false
    
    let types: [TopicType]
    let info: NSAttributedString?
    let attachments: [Post.Attachment]
    
    var body: some View {
        VStack {
            HStack {
                if let info {
                    RichText(text: "Спойлер: ".asNSAttributedString() + info) {
                        ($0 as? UITextView)?.isSelectable = false
                    }
                } else {
                    RichText(text: "Спойлер".asNSAttributedString()) {
                        ($0 as? UITextView)?.isSelectable = false
                    }
                }
                
                Spacer()
                
                Image(systemSymbol: isExpanded ? .chevronUp : .chevronDown)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .background(Color.Main.primaryAlpha)
            .onTapGesture {
                isExpanded.toggle()
            }
            
            if isExpanded {
                ForEach(types, id: \.self) { type in
                    TopicView(type: type, attachments: attachments)
                }
                .padding(8)
            }
        }
        .border(Color.Main.primaryAlpha)
        .animation(.default, value: isExpanded)
    }
}

#Preview {
    VStack(spacing: 8) {
//        TopicView(type: .text(NSAttributedString(string: "test")), attachments: [])
//        
//        TopicView(type: .image(URL(string: "https://4pda.to/s/Zy0hVVliEZZvbylgfQy11QiIjvDIhLJBjheakj4yIz2ohhN2F.jpg")!))
//            .frame(width: 100, height: 100)
//            .clipped()
//        
//        TopicView(type: .spoiler([.text(NSAttributedString(string: "123"))]))
    }
}

// TODO: Move to Extensions?
func + (left: NSAttributedString, right: NSAttributedString) -> NSAttributedString {
    let result = NSMutableAttributedString()
    result.append(left)
    result.append(right)
    return result
}

// TODO: Move to Extensions?
extension String {
    func asNSAttributedString(
        font: UIFont.TextStyle = .body,
        color: UIColor = UIColor.label
    ) -> NSAttributedString {
        NSAttributedString(
            string: self,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: font),
                .foregroundColor: color
            ]
        )
    }
}
