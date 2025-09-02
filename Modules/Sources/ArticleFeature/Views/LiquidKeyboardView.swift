//
//  LiquidKeyboardView.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 28.08.2025.
//

import SwiftUI
import ComposableArchitecture
import SFSafeSymbols
import NukeUI
import Models

@available(iOS 26.0, *)
struct LiquidKeyboardView: View {
    
    // MARK: - Properties
    
    @Perception.Bindable var store: StoreOf<ArticleFeature>
    @FocusState.Binding var focus: ArticleFeature.State.Field?
    @Binding var isExpanded: Bool
    @Binding var isScrollDownVisible: Bool
    @Namespace private var namespace
    @Environment(\.tintColor) private var tintColor
    
    var onScrollDownTapped: () -> Void
    
    private var isTextEmpty: Bool {
        return store.commentText.isEmpty
    }
    
    // MARK: - Init
    
    init(
        store: StoreOf<ArticleFeature>,
        focus: FocusState<ArticleFeature.State.Field?>.Binding,
        isExpanded: Binding<Bool>,
        isScrollDownVisible: Binding<Bool>,
        onScrollDownTapped: @escaping () -> Void
    ) {
        self.store = store
        self._focus = focus
        self._isExpanded = isExpanded
        self._isScrollDownVisible = isScrollDownVisible
        self.onScrollDownTapped = onScrollDownTapped
    }
    
    // MARK: - Body
    
    var body: some View {
        WithPerceptionTracking {
            GlassEffectContainer(spacing: 16) {
                VStack(spacing: 10) {
                    if let comment = store.replyComment {
                        ReplyView(comment: comment)
                    }
                    
                    HStack(alignment: .bottom, spacing: 16) {
                        if isExpanded {
                            TextFieldView()
                        }
                        
                        VStack(spacing: 16) {
                            if isScrollDownVisible {
                                ScrollButton()
                            }
                            
                            SendButton()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .onChange(of: store.replyComment) { _ in
                if store.replyComment != nil && !isExpanded {
                    isExpanded = true
                } else if store.replyComment == nil && isTextEmpty && isExpanded {
                    isExpanded = false
                }
            }
            .animation(.default, value: store.canComment)
            .animation(.default, value: isTextEmpty)
            .animation(.default, value: isExpanded)
            .animation(.default, value: isScrollDownVisible)
        }
    }
    
    // MARK: - Reply View
    
    @ViewBuilder
    private func ReplyView(comment: Comment) -> some View {
        HStack(spacing: 0) {
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
            .contentShape(.rect)
            .padding(.trailing, 8)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(8)
        .contentShape(.rect)
        .glassEffect(in: RoundedRectangle(cornerRadius: 20))
        .glassEffectID("reply", in: namespace)
        .transition(.move(edge: .bottom))
    }
    
    // MARK: - Text Field View
    
    @ViewBuilder
    private func TextFieldView() -> some View {
        TextField(text: $store.commentText.removeDuplicates(), axis: .vertical) {
            Text("Comment...", bundle: .module)
                .font(.subheadline)
                .foregroundStyle(Color(.Labels.quintuple))
        }
        .font(.subheadline)
        .foregroundStyle(Color(.Labels.primary))
        .lineLimit(1...10)
        .focused($focus, equals: ArticleFeature.State.Field.comment)
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .glassEffect(in: RoundedRectangle(cornerRadius: 20))
        .glassEffectID("field", in: namespace)
        .transition(.move(edge: .trailing))
        .disabled(store.isUploadingComment)
    }
    
    // MARK: - Scroll Button
    
    @ViewBuilder
    private func ScrollButton() -> some View {
        Button {
            onScrollDownTapped()
        } label: {
            Image(systemSymbol: .arrowDown)
                .foregroundStyle(tintColor)
        }
        .frame(width: 44, height: 44)
        .contentShape(.rect)
        .glassEffect(.regular.interactive())
        .glassEffectID("comments", in: namespace)
    }
    
    // MARK: - Send Button
    
    @ViewBuilder
    private func SendButton() -> some View {
        Button {
            if isExpanded, !isTextEmpty {
                store.send(.sendCommentButtonTapped)
            } else {
                isExpanded.toggle()
            }
        } label: {
            if store.isUploadingComment {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
            } else {
                let symbol: SFSymbol = isExpanded
                ? (isTextEmpty ? .xmark : .arrowUp)
                : .squareAndPencil
                Image(systemSymbol: symbol)
                    .foregroundStyle(foregroundStyle())
                    .replaceDownUpByLayerEffect(value: true)
            }
        }
        .frame(width: 44, height: 44)
        .contentShape(.rect)
        .glassEffect(
            .regular
                .tint(isTextEmpty ? .clear : tintColor)
                .interactive()
        )
        .glassEffectID("button", in: namespace)
        .disabled(store.isUploadingComment || !store.canComment)
    }
    
    private func foregroundStyle() -> AnyShapeStyle {
        if !store.canComment {
            AnyShapeStyle(Color.gray)
        } else if isTextEmpty {
            AnyShapeStyle(tintColor)
        } else {
            AnyShapeStyle(Color.white)
        }
    }
}
