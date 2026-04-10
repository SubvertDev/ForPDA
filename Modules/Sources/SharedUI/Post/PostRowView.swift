//
//  PostRowView.swift
//  ForPDA
//
//  Created by Xialtal on 20.11.25.
//

import SwiftUI
import NukeUI
import Models
import SFSafeSymbols

public struct PostRowView: View {
    
    // MARK: - Enums
    
    public enum PostAction {
        case userTapped
        case urlTapped(URL)
        case imageTapped(URL)
        case textQuoted(String)
    }
    
    // MARK: - Properties
    
    public let state: State
    public let action: (PostAction) -> Void
    public let menuAction: (PostMenuAction) -> Void
    
    // MARK: - Init
    
    public init(
        state: State,
        action: @escaping (PostAction) -> Void,
        menuAction: @escaping (PostMenuAction) -> Void
    ) {
        self.state = state
        self.action = action
        self.menuAction = menuAction
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            Header()
            PostBody(state.post)
            if let lastEdit = state.post.post.lastEdit {
                Footer(lastEdit)
            }
            PostStatus()
        }
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private func Header() -> some View {
        HStack(spacing: 8) {
            LazyImage(url: URL(string: state.post.post.author.avatarUrl)) { state in
                if let image = state.image {
                    image.resizable().scaledToFill()
                } else {
                    Image(.avatarDefault).resizable().scaledToFill()
                }
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
            .onTapGesture {
                action(.userTapped)
            }
            
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Group {
                        Text(state.post.post.author.name)
                            .font(.subheadline)
                            .bold()
                            .foregroundStyle(Color(.Labels.primary))
                            .lineLimit(1)
                        
                        Text(String(state.post.post.author.reputationCount))
                            .font(.caption)
                            .foregroundStyle(Color(.Labels.secondary))
                            .padding(.vertical, 4)
                            .padding(.horizontal, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .foregroundStyle(Color(.Background.teritary))
                            )
                    }
                    .onTapGesture {
                        action(.userTapped)
                    }
                    
                    Spacer()
                    
                    if state.post.post.karma != 0 {
                        Text(String(state.post.post.karma))
                            .font(.caption)
                            .foregroundStyle(Color(.Labels.primary))
                    }
                }
                
                HStack(spacing: 8) {
                    Text(User.Group(rawValue: state.post.post.author.groupId)!.title)
                        .font(.caption)
                        .foregroundStyle(Color(.Labels.teritary))
                    
                    Spacer()
                    
                    if state.post.post.canModerate, state.post.post.isProtected {
                        Image(systemSymbol: .shield)
                            .font(.caption)
                            .foregroundStyle(Color(.Labels.quaternary))
                    }
                    
                    Text(state.post.post.createdAt.formattedDate(), bundle: .module)
                        .font(.caption)
                        .foregroundStyle(Color(.Labels.quaternary))
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            
            if state.isContextMenuAvailable {
                ContextMenu()
            }
        }
    }
    
    // MARK: - Body

    @ViewBuilder
    private func PostBody(_ post: UIPost) -> some View {
        VStack(spacing: 8) {
            ForEach(post.content, id: \.self) { type in
                TopicView(
                    type: type.value,
                    attachments: post.post.attachments,
                    onUrlTap: { url in
                        action(.urlTapped(url))
                    },
                    onImageTap: { url in
                        action(.imageTapped(url))
                    },
                    onQuote: { text in
                        action(.textQuoted(text))
                    }
                )
            }
        }
    }
    
    // MARK: - Post Status
    
    @ViewBuilder
    private func PostStatus() -> some View {
        if state.post.post.isDeleted {
            PostStatusLabel(icon: .trash, text: "This post deleted")
        } else if state.post.post.isHidden {
            PostStatusLabel(icon: .eyeSlash, text: "This post hidden")
        }
    }
        
    private func PostStatusLabel(icon: SFSymbol, text: LocalizedStringKey) -> some View {
        HStack(spacing: 6) {
            Image(systemSymbol: icon)
            Text(text, bundle: .module)
        }
        .font(.caption2)
        .foregroundStyle(.red)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Footer
    
    @ViewBuilder
    private func Footer(_ lastEdit: Post.LastEdit) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            let link = "https://4pda.to/forum/index.php?showuser=\(lastEdit.userId)"
            Text(LocalizedStringResource("Edited: [\(lastEdit.username)](\(link)) • \(lastEdit.date.formatted())", bundle: .module))
                .environment(\.openURL, OpenURLAction(handler: { url in
                    action(.urlTapped(url))
                    return .handled
                }))
            
            if !lastEdit.reason.isEmpty {
                Text("Reason: \(lastEdit.reason)", bundle: .module)
            }
        }
        .font(.caption2)
        .foregroundStyle(Color(.Labels.teritary))
        .padding(.top, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Context Menu
    
    private func ContextMenu() -> some View {
        Menu {
            if state.canPostInTopic {
                Section {
                    ContextButton(text: LocalizedStringResource("Reply", bundle: .module), symbol: .arrowTurnUpRight) {
                        menuAction(.reply(state.post.id, state.post.post.author.name))
                    }
                }
            }
            
            if state.isUserAuthorized, state.sessionUserId != state.post.post.author.id, state.post.post.canChangeKarma {
                ContextButton(text: LocalizedStringResource("Rate", bundle: .module), symbol: .chevronUpChevronDown) {
                    menuAction(.karma(state.post.id))
                }
            }
            
            if state.post.post.canEdit {
                ContextButton(text: LocalizedStringResource("Edit", bundle: .module), symbol: .squareAndPencil) {
                    menuAction(.edit(state.post.post))
                }
            }
            
            if state.isUserAuthorized {
                ContextButton(text: LocalizedStringResource("Report", bundle: .module), symbol: .exclamationmarkTriangle) {
                    menuAction(.report(state.post.id))
                }
            }
            
            if state.post.post.canDelete {
                ContextButton(text: LocalizedStringResource("Delete", bundle: .module), symbol: .trash) {
                    menuAction(.tools(.delete, state.post.id, false))
                }
            }
            
            if state.post.post.canModerate {
                ToolsContextMenu()
            }
            
            Section {
                if state.isUserAuthorized, state.post.post.author.id != state.sessionUserId {
                    ContextButton(text: LocalizedStringResource("Reputation", bundle: .module), symbol: .plusminus) {
                        menuAction(.changeReputation(state.post.id, state.post.post.author.id, state.post.post.author.name))
                    }
                }
                
                ContextButton(
                    text: LocalizedStringResource("Search «\(state.post.post.author.name)» posts", bundle: .module),
                    symbol: userPostsInTopicIcon
                ) {
                    menuAction(.userPostsInTopic(state.post.post.author.id))
                }
                
                ContextButton(text: LocalizedStringResource("Post Mentions", bundle: .module), symbol: .arrowRightSquare) {
                    menuAction(.mentions(state.post.id))
                }
            }
            
            Section {
                ContextButton(text: LocalizedStringResource("Copy Link", bundle: .module), symbol: .docOnDoc) {
                    menuAction(.copyLink(state.post.id))
                }
            }
        } label: {
            Image(systemSymbol: .ellipsis)
                .font(.body)
                .foregroundStyle(Color(.Labels.teritary))
                .padding(.horizontal, 8) // Padding for tap area
                .padding(.vertical, 16)
                .rotationEffect(.degrees(90))
        }
        .onTapGesture {} // DO NOT DELETE, FIX FOR IOS 17
        .frame(width: 8, height: 22)
    }
    
    // MARK: - Tools Context Menu
    
    @ViewBuilder
    private func ToolsContextMenu() -> some View {
        Menu {
            if state.post.post.isDeleted {
                ContextButton(
                    text: LocalizedStringResource("Restore", bundle: .module),
                    symbol: .arrowCounterclockwiseCircle
                ) {
                    menuAction(.tools(.delete, state.post.id, true))
                }
            }
            
            ContextButton(
                text: state.post.post.isHidden
                ? LocalizedStringResource("Remove Hide", bundle: .module)
                : LocalizedStringResource("Hide", bundle: .module),
                symbol: state.post.post.isHidden ? .eyeSlashFill : .eyeSlash
            ) {
                menuAction(.tools(.hide, state.post.id, !state.post.post.isHidden))
            }
            
            ContextButton(
                text: state.post.post.isPinned
                ? LocalizedStringResource("Unpin", bundle: .module)
                : LocalizedStringResource("Pin", bundle: .module),
                symbol: state.post.post.isPinned ? .pinFill : .pin
            ) {
                menuAction(.tools(.pin, state.post.id, !state.post.post.isPinned))
            }
            
            ContextButton(
                text: state.post.post.isProtected
                ? LocalizedStringResource("Remove Protection", bundle: .module)
                : LocalizedStringResource("Protect", bundle: .module),
                symbol: state.post.post.isProtected ? .shieldFill : .shield
            ) {
                menuAction(.tools(.protect, state.post.id, !state.post.post.isProtected))
            }
        } label: {
            HStack {
                Text("Tools", bundle: .module)
                Image(systemSymbol: .shield)
            }
        }
    }
}

// MARK: - User Posts In Topic Icon

@available(iOS, deprecated: 18.0)
fileprivate extension PostRowView {
    private var userPostsInTopicIcon: SFSymbol {
        if #available(iOS 18.0, *) {
            return .textPageBadgeMagnifyingglass
        } else {
            return .docTextMagnifyingglass
        }
    }
}

// MARK: - State Model

public extension PostRowView {
    struct State: Equatable {
        public let post: UIPost
        public let sessionUserId: Int
        
        public let canPostInTopic: Bool
        
        public let isUserAuthorized: Bool
        public let isContextMenuAvailable: Bool
        
        public init(
            post: UIPost,
            sessionUserId: Int = 0,
            canPostInTopic: Bool = false,
            isUserAuthorized: Bool = false,
            isContextMenuAvailable: Bool = false
        ) {
            self.post = post
            self.sessionUserId = sessionUserId
            self.canPostInTopic = canPostInTopic
            self.isUserAuthorized = isUserAuthorized
            self.isContextMenuAvailable = isContextMenuAvailable
        }
    }
}
