//
//  CommentsView.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 28.07.2024.
//

import SwiftUI
import ComposableArchitecture
import Models
import NukeUI
import SharedUI
import SkeletonUI
import SFSafeSymbols

// MARK: - Comments View

struct CommentsView: View {
        
    let store: StoreOf<ArticleFeature>
    let comments: [Comment]
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Comments (\(comments.count.description)):", bundle: .module)
                .font(.title3)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
            
            VStack(spacing: 4) {
                ForEach(comments.filter { $0.parentId == 0 }) { comment in
                    CommentView(
                        comments: comments,
                        comment: comment,
                        indentationLevel: indentationLevel(for: comment),
                        onCommentHeaderTapped: { comment in
                            store.send(.delegate(.commentHeaderTapped(comment.authorId)))
                        },
                        onCommentLikeButtonTapped: { id in
                            store.send(.likeButtonTapped(id))
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // TODO: Optimize alghoritm?
    private func indentationLevel(for comment: Comment, level: Int = 0) -> Int {
        var level: Int = level
        if comment.parentId != 0 {
            level += 1
            let parentComment = comments.first(where: { $0.id == comment.parentId })
            return indentationLevel(for: parentComment!, level: level)
        } else {
            return level
        }
    }
}

// MARK: - Comment View

struct CommentView: View {
    
    // MARK: - Properties
    
    @Environment(\.tintColor) private var tintColor
    @State private var isLiked: Bool
    @State private var likesAmount: Int

    let comments: [Comment]
    let comment: Comment
    let indentationLevel: Int
    let onCommentHeaderTapped: (Comment) -> Void
    let onCommentLikeButtonTapped: (Int) -> Void
    
    init(
        comments: [Comment],
        comment: Comment,
        indentationLevel: Int,
        onCommentHeaderTapped: @escaping (Comment) -> Void,
        onCommentLikeButtonTapped: @escaping (Int) -> Void
    ) {
        self.isLiked = comment.type == .liked
        self.likesAmount = comment.likesAmount
        self.comments = comments
        self.comment = comment
        self.indentationLevel = indentationLevel
        self.onCommentHeaderTapped = onCommentHeaderTapped
        self.onCommentLikeButtonTapped = onCommentLikeButtonTapped
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if comment.type == .deleted {
                    Text("Comment has been deleted", bundle: .module)
                        .font(.subheadline)
                        .foregroundStyle(Color.Labels.quaternary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 16)
                } else {
                    VStack(spacing: 6) {
                        Header()
                        
                        Text(comment.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                        
                        Footer()
                    }
                    .padding(.bottom, 16)
                    .overlay(alignment: .topLeading) {
                        Rectangle()
                            .foregroundStyle(Color.Background.primary)
                            .frame(width: 128, height: 16)
                            .offset(x: -1, y: -16)
                    }
                }
            }
            .overlay(alignment: .leading) {
                if indentationLevel > 0 {
                    HStack(spacing: 0) {
                        ForEach(1...indentationLevel, id: \.self) { index in
                            Rectangle()
                                .frame(width: 1)
                                .foregroundStyle(Color.Separator.secondary)
                                .offset(x: CGFloat(-17 * index))
                        }
                    }
                }
            }
            .padding(.leading, 16 * CGFloat(indentationLevel))
            
            ForEach(comment.childIds, id: \.self) { id in
                CommentView(
                    comments: comments,
                    comment: comments.first(where: { $0.id == id })!,
                    indentationLevel: indentationLevel + 1,
                    onCommentHeaderTapped: onCommentHeaderTapped,
                    onCommentLikeButtonTapped: onCommentLikeButtonTapped
                )
            }
        }
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private func Header() -> some View {
        HStack(spacing: 6) {
            Group {
                LazyImage(url: comment.avatarUrl) { state in
                    Group {
                        if let image = state.image {
                            image.resizable().scaledToFill()
                        } else {
                            Image.avatarDefault.resizable()
                        }
                    }
                    .skeleton(with: state.isLoading, shape: .rectangle)
                }
                .frame(width: 26, height: 26)
                .clipShape(Circle())
                .padding(.trailing, 2)
                
                Text(comment.authorName)
                    .font(.footnote)
                    .bold()
                    .foregroundStyle(Color.Labels.teritary)
                    .bold()
            }
            .onTapGesture {
                onCommentHeaderTapped(comment)
            }
            
            Group {
                Text(String("·"))
                Text(format(date: comment.date), bundle: .module)
            }
            .font(.footnote)
            .foregroundStyle(Color.Labels.teritary)
            
            Spacer()
        }
    }
    
    // MARK: - Footer
    
    @ViewBuilder
    private func Footer() -> some View {
        HStack(spacing: 2) {
            if comment.type == .edited {
                Text("Edited", bundle: .module)
                    .font(.caption)
                    .foregroundStyle(Color.Labels.teritary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
            
            ActionButton(symbol: .ellipsis) {}
            ActionButton(symbol: .arrowTurnUpLeft) {}
            LikeButton()
            Text(String(likesAmount))
                .font(.subheadline)
                .foregroundStyle(Color.Labels.teritary)
                .padding(.trailing, 6)
        }
    }
    
    // MARK: - Action Button
    
    @ViewBuilder
    private func ActionButton(
        symbol: SFSymbol,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            
        } label: {
            Image(systemSymbol: symbol)
                .font(.body)
                .foregroundStyle(Color.Labels.teritary)
        }
        .frame(width: 32, height: 32)
    }
    
    // MARK: - Like Button
    
    @ViewBuilder
    private func LikeButton() -> some View {
        Button {
            if !isLiked {
                isLiked = true
                likesAmount += 1
                onCommentLikeButtonTapped(comment.id)
            }
        } label: {
            Image(systemSymbol: isLiked ? .handThumbsupFill : .handThumbsup)
                .font(.body)
                .foregroundStyle(isLiked ? tintColor : Color.Labels.teritary)
                .bounceDownWholeSymbolEffect(value: isLiked)
        }
        .frame(width: 32, height: 32)
    }
}

// MARK: Helpers

extension CommentView {
    func format(date: Date) -> LocalizedStringKey {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: Date.now)
        
        if let minutes = components.minute, minutes < 60, components.hour == 0, components.day == 0 {
            return "\(minutes)m"
        } else if let hours = components.hour, hours < 24, components.day == 0 {
            return "\(hours)h"
        } else {
            formatter.dateFormat = "dd.MM.yy"
            return LocalizedStringKey(formatter.string(from: date))
        }
    }
}

// MARK: - Previews

#Preview {
    VStack {
        CommentsView(
            store: Store(
                initialState: ArticleFeature.State(articlePreview: .mock),
                reducer: {
                    ArticleFeature()
                }),
            comments: .mockArray
        )
        
        Rectangle()
            .foregroundColor(Color(.systemGray6))
    }
}
