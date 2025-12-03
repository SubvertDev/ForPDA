//
//  PostRowView.swift
//  ForPDA
//
//  Created by Xialtal on 20.11.25.
//

import SwiftUI
import NukeUI
import Models

public struct PostRowView: View {
    
    // MARK: - Enums
    
    public enum PostAction {
        case userTapped, urlTapped(URL), imageTapped(URL)
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
                    
                    Text(state.post.post.createdAt.formattedDate(), bundle: .module)
                        .font(.caption)
                        .foregroundStyle(Color(.Labels.quaternary))
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            
            if state.isContextMenuAvailable, state.isUserAuthorized, state.canPostInTopic {
                ContextMenu()
            }
        }
    }
    
    // MARK: - Body

    @ViewBuilder
    private func PostBody(_ post: UIPost) -> some View {
        VStack(spacing: 8) {
            ForEach(post.content, id: \.self) { type in
                TopicView(type: type.value, attachments: post.post.attachments) { url in
                    action(.urlTapped(url))
                } onImageTap: { url in
                    action(.imageTapped(url))
                }
            }
        }
    }
    
    // MARK: - Footer
    
    @ViewBuilder
    private func Footer(_ lastEdit: Post.LastEdit) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Edited: \(lastEdit.username) • \(lastEdit.date.formatted())", bundle: .module)
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
            Section {
                ContextButton(text: LocalizedStringResource("Reply", bundle: .module), symbol: .arrowTurnUpRight) {
                    menuAction(.reply(state.post.id, state.post.post.author.name))
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
            
            ContextButton(text: LocalizedStringResource("Report", bundle: .module), symbol: .exclamationmarkTriangle) {
                menuAction(.report(state.post.id))
            }
            
            if state.post.post.canDelete {
                ContextButton(text: LocalizedStringResource("Delete", bundle: .module), symbol: .trash) {
                    menuAction(.delete(state.post.id))
                }
            }
            
            Section {
                if state.isUserAuthorized, state.post.post.author.id != state.sessionUserId {
                    ContextButton(text: LocalizedStringResource("Reputation", bundle: .module), symbol: .plusminus) {
                        menuAction(.changeReputation(state.post.id, state.post.post.author.id, state.post.post.author.name))
                    }
                }
                
                ContextButton(text: LocalizedStringResource("Post Mentions", bundle: .module), symbol: .arrowRightSquare) {
                    menuAction(.postMentions(state.post.id))
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
