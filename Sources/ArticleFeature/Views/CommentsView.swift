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

// MARK: - Comments View

struct CommentsView: View {
    
    let store: StoreOf<ArticleFeature>
    let comments: [Comment]
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .frame(maxWidth: .infinity, maxHeight: 4)
                .foregroundStyle(Color(.systemGray6))
            
            Text("Comments (\(comments.count.description)):", bundle: .module)
                .font(.title2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
            
            VStack(spacing: 4) {
                ForEach(comments.filter { $0.parentId == 0 }) { comment in
                    CommentView(
                        comments: comments,
                        comment: comment,
                        indentationLevel: indentationLevel(for: comment),
                        onCommentHeaderTapped: { comment in
                            store.send(.delegate(.commentHeaderTapped(comment.authorId)))
                        }
                    )
                }
            }
            .padding(.top, 4)
            .background(Color(.systemGray6))
        }
    }
    
    // TODO: Optimize alghoritm?
    private func indentationLevel(for comment: Comment, level: CGFloat = 0) -> CGFloat {
        var level: CGFloat = level
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
    
    let comments: [Comment]
    let comment: Comment
    let indentationLevel: CGFloat
    let onCommentHeaderTapped: (Comment) -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Color(.systemBackground)
                
                if comment.type == .deleted {
                    Text("(Comment has been deleted)", bundle: .module)
                        .font(.body)
                        .foregroundStyle(Color(.systemGray))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                } else {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Group {
                                LazyImage(url: comment.avatarUrl) { state in
                                    if let image = state.image {
                                        image.resizable().scaledToFill()
                                    } else if state.error != nil {
                                        Image.avatarDefault.resizable()
                                    }
                                }
                                .frame(width: 24, height: 24)
                                .clipped()
                                
                                Text(comment.authorName)
                                    .font(.callout)
                                    .foregroundStyle(Color(.systemGray))
                                    .bold()
                            }
                            .onTapGesture {
                                onCommentHeaderTapped(comment)
                            }
                            
                            Spacer()
                            
                            if comment.likesAmount > 0 {
                                Text(comment.likesAmount.description)
                                    .font(.body)
                                    .padding(.horizontal, 4)
                                    .background(Color(.systemGray5))
                            }
                            
                            Text(comment.formattedDate)
                                .font(.callout)
                        }
                        
                        Text(comment.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                        
                        if comment.type == .edited {
                            Text("(edited)", bundle: .module)
                                .font(.footnote)
                                .foregroundStyle(Color(.systemGray))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(8)
                }
            }
            .padding(.leading, 8 * indentationLevel)
            
            ForEach(comment.childIds, id: \.self) { id in
                CommentView(
                    comments: comments,
                    comment: comments.first(where: { $0.id == id })!,
                    indentationLevel: indentationLevel + 1,
                    onCommentHeaderTapped: onCommentHeaderTapped
                )
            }
        }
    }
}

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
