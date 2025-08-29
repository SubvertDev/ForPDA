//
//  KeyboardView.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 29.08.2025.
//

import SwiftUI
import NukeUI
import ComposableArchitecture
import Models

struct KeyboardView: View {
    
    // MARK: - Properties
    
    @Perception.Bindable var store: StoreOf<ArticleFeature>
    @FocusState.Binding var focus: ArticleFeature.State.Field?
    @Binding var isScrollDownVisible: Bool
    @Environment(\.tintColor) private var tintColor
    
    var onScrollDownTapped: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            // Not available below 18 due to scroll position detection
            if #available(iOS 18.0, *) {
                if isScrollDownVisible {
                    ScrollButton()
                }
            }
            
            VStack(spacing: 10) {
                if let comment = store.replyComment {
                    ReplyView(comment: comment)
                }
                
                HStack(alignment: .bottom, spacing: 8) {
                    TextFieldView()
                    
                    if !store.commentText.isEmpty {
                        SendButton()
                    }
                }
                .animation(.default, value: store.commentText.isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 6)
            .background(Color(.Background.primaryAlpha))
            .background(.ultraThinMaterial)
        }
        .animation(.default, value: store.replyComment)
        .animation(.default, value: isScrollDownVisible)
    }
    
    // MARK: - Scroll Button
    
    @ViewBuilder
    private func ScrollButton() -> some View {
        Button {
            onScrollDownTapped()
        } label: {
            Circle()
                .fill(Color(.Background.primary))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemSymbol: .arrowDown)
                        .tint(tintColor)
                }
        }
        .shadow(color: .black.opacity(0.1), radius: 2)
        .padding(.trailing, 8)
    }
    
    // MARK: - Reply View
    
    @ViewBuilder
    private func ReplyView(comment: Comment) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(tintColor)
                .frame(width: 1)
                .padding(.trailing, 8)
            
            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    LazyImage(url: store.replyComment?.avatarUrl) { state in
                        if let image = state.image { image.resizable().scaledToFill() }
                    }
                    .clipShape(Circle())
                    .frame(width: 20, height: 20)
                    
                    Text(comment.authorName)
                        .font(.caption2)
                        .bold()
                        .foregroundStyle(Color(.Labels.teritary))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Text(comment.text)
                    .lineLimit(2)
                    .font(.footnote)
                    .foregroundStyle(Color(.Labels.primary))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.trailing, 6)
            
            Button {
                store.send(.removeReplyCommentButtonTapped)
            } label: {
                Image(systemSymbol: .xmark)
                    .font(.body)
                    .tint(tintColor)
            }
            .frame(width: 32, height: 32)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
    
    // MARK: - Text Field View
    
    @ViewBuilder
    private func TextFieldView() -> some View {
        TextField(text: $store.commentText.removeDuplicates()) {
            Text("Comment...", bundle: .module)
                .font(.subheadline)
                .foregroundStyle(Color(.Labels.quintuple))
        }
        .font(.subheadline)
        .foregroundStyle(Color(.Labels.primary))
        .lineLimit(1...10)
        .focused($focus, equals: ArticleFeature.State.Field.comment)
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(Color(.Background.teritary))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(.Separator.secondary), lineWidth: 0.33)
        }
    }
    
    // MARK: - Send Button
    
    @ViewBuilder
    private func SendButton() -> some View {
        Button {
            store.send(.sendCommentButtonTapped)
        } label: {
            ZStack {
                Circle()
                    .fill(tintColor)
                
                if store.isUploadingComment {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Color(.Labels.primaryInvariably))
                } else {
                    Image(systemSymbol: .arrowUp)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(Color(.Labels.primaryInvariably))
                }
            }
            .frame(width: 34, height: 34)
        }
        .disabled(store.isUploadingComment)
    }
}
