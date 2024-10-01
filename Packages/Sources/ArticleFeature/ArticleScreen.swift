//
//  NewsScreen.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import SwiftUI
import UIKit
import ComposableArchitecture
import NukeUI
import SFSafeSymbols
import YouTubePlayerKit
import Models
import SharedUI
import SkeletonUI
import SmoothGradient

// TODO: Move somewhere else
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}

public struct ArticleScreen: View {
    
    @Perception.Bindable public var store: StoreOf<ArticleFeature>
    @FocusState public var focus: ArticleFeature.State.Field?
    @Environment(\.tintColor) private var tintColor
    
    @State private var safeAreaTopHeight: CGFloat = UIApplication.topSafeArea + 44 // (status + navbar)
    @State private var navBarOpacity: CGFloat = 0
    private var navBarFullyVisible: Bool {
        return navBarOpacity >= 1
    }
    
    public init(store: StoreOf<ArticleFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ArticleScrollView()
                .safeAreaInset(edge: .bottom) {
                    Group {
                        if store.canComment {
                            Keyboard()
                                .transition(.push(from: .bottom))
                        }
                    }
                    .animation(.default, value: store.canComment)
                }
                .onTapGesture {
                    focus = nil
                }
                .bind($store.focus, to: $focus)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden()
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbar {
                    ToolbarButton(placement: .topBarLeading, symbol: .chevronLeft) {
                        store.send(.backButtonTapped)
                    }
                    ToolbarButton(placement: .topBarTrailing, symbol: .bookmark) {
                        store.send(.bookmarkButtonTapped)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        ArticleMenu(store: store, isDark: navBarFullyVisible)
                    }
                }
                .overlay(alignment: .top) {
                    Color.Background.primaryAlpha
                        .opacity(navBarOpacity)
                        .frame(width: UIScreen.main.bounds.width, height: safeAreaTopHeight)
                        .ignoresSafeArea()
                }
                .overlay {
                    RefreshIndicator()
                }
                .background(Color.Background.primary)
                .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
                .sheet(item: $store.destination.share, id: \.self) { url in
                    // FIXME: Perceptible warning despite tracking closure
                    WithPerceptionTracking {
                        ShareActivityView(url: url) { success in
                            store.send(.linkShared(success, url))
                        }
                        .presentationDetents([.medium])
                    }
                }
                .task {
                    store.send(.onTask)
                }
        }
    }
    
    // MARK: - Scroll View
    
    @ViewBuilder
    private func ArticleScrollView() -> some View {
        ScrollView(.vertical) {
            VStack(spacing: 0) {
                ParallaxHeader(
                    coordinateSpace: "scroll",
                    defaultHeight: UIScreen.main.bounds.width,
                    safeAreaTopHeight: safeAreaTopHeight
                ) {
                    ArticleHeader()
                }
                
                if store.isLoading {
                    ArticleLoader()
                } else if let elements = store.elements {
                    ArticleView(elements: elements)
                        .background(Color.Background.primary)
                }
            }
            .animation(.default, value: store.elements)
            .modifier(
                ScrollViewOffsetObserver(
                    safeAreaTopHeight: safeAreaTopHeight,
                    navBarOpacity: $navBarOpacity
                ) {
                    if !store.isRefreshing {
                        store.send(.onRefresh)
                    }
                }
            )
        }
        .ignoresSafeArea(.all, edges: .top)
        .scrollIndicators(.hidden)
        .coordinateSpace(name: "scroll")
    }
    
    // MARK: - Article Header
    
    @ViewBuilder
    private func ArticleHeader() -> some View {
        ZStack {
            LazyImage(url: store.articlePreview.imageUrl) { state in
                Group {
                    if let image = state.image {
                        image.resizable().scaledToFill()
                    } else {
                        Color.Background.forcedDark
                    }
                }
                .skeleton(
                    with: state.isLoading,
                    appearance: .gradient(
                        .linear,
                        color: Color.Labels.forcedLight.opacity(0.25),
                        background: Color.Background.forcedDark,
                        radius: 1,
                        angle: .zero
                    ),
                    shape: .rectangle
                )
            }
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 0) {
                    Text(store.articlePreview.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.Labels.forcedLight)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 8)
                    
                    HStack {
                        Text(store.articlePreview.authorName)
                        Spacer()
                        Text(store.articlePreview.formattedDate)
                    }
                    .font(.caption)
                    .foregroundStyle(Color.Labels.secondaryInvariably)
                }
                .padding(.top, 32)
                .padding(16)
                .background(
                    LinearGradient(
                        gradient: .smooth(
                            from: .clear,
                            to: Color.Background.forcedDark,
                            easing: .easeInOut
                        ),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .frame(maxWidth: UIScreen.main.bounds.width)
        }
    }
    
    // MARK: - Article + Comments View
    
    @ViewBuilder
    private func ArticleView(elements: [ArticleElement]) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                ForEach(elements, id: \.self) { element in
                    WithPerceptionTracking {
                        ArticleElementView(store: store, element: element)
                            .padding(.vertical, 10)
                    }
                }
            }
            .padding(.vertical, 14)
            
            Rectangle()
                .frame(maxWidth: .infinity, maxHeight: 16)
                .foregroundStyle(Color.Background.teritary)
            
            CommentsView(store: store)
        }
    }
    
    // MARK: - Keyboard
    
    @ViewBuilder
    private func Keyboard() -> some View {
        VStack(spacing: 10) {
            if let comment = store.replyComment {
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
                                .foregroundStyle(Color.Labels.teritary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        Text(comment.text)
                            .lineLimit(2)
                            .font(.footnote)
                            .foregroundStyle(Color.Labels.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.trailing, 6)
                    
                    Button {
                        store.send(.removeReplyCommentButtonTapped)
                    } label: {
                        Image(systemSymbol: .xmark)
                            .font(.body)
                    }
                    .frame(width: 32, height: 32)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            
            HStack(alignment: .bottom, spacing: 8) {
                TextField("Message", text: $store.commentText.removeDuplicates(), axis: .vertical)
                    .font(.subheadline)
                    .foregroundStyle(Color.Labels.primary)
                    .lineLimit(1...10)
                    .focused($focus, equals: ArticleFeature.State.Field.comment)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .background(Color.Background.teritary)
                    .background(Color.Background.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.Separator.secondary, lineWidth: 0.33)
                    }
                
                Button {
                    store.send(.sendCommentButtonTapped)
                } label: {
                    ZStack {
                        Circle()
                            .fill(tintColor)
                        
                        if store.isUploadingComment {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(Color.Labels.primaryInvariably)
                        } else {
                            Image(systemSymbol: .arrowUp)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.Labels.primaryInvariably)
                        }
                    }
                    .frame(width: 34, height: 34)
                }
                .disabled(store.isUploadingComment)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(Color.Background.primaryAlpha)
        .animation(.default, value: store.replyComment)
    }
    
    // MARK: - Toolbar Button
    
    @ToolbarContentBuilder
    private func ToolbarButton(
        placement: ToolbarItemPlacement,
        symbol: SFSymbol,
        action: @escaping () -> Void
    ) -> some ToolbarContent {
        ToolbarItem(placement: placement) {
            Button {
                action()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.clear)
                        .background(.ultraThinMaterial)
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                    
                    Image(systemSymbol: symbol)
                        .font(.body)
                        .foregroundStyle(navBarFullyVisible ? Color.Labels.teritary : Color.Labels.primaryInvariably)
                        .scaleEffect(0.8) // TODO: ?
                }
            }
            .animation(.default, value: navBarFullyVisible)
        }
    }
    
    // MARK: - Article Loader
    
    @ViewBuilder
    private func ArticleLoader() -> some View {
        VStack {
            ModernCircularLoader()
                .frame(width: 24, height: 24)
            
            Text("Loading article...", bundle: .module)
        }
    }
    
    // MARK: - Refresh Indicator
    
    @ViewBuilder
    private func RefreshIndicator() -> some View {
        VStack {
            if store.isRefreshing {
                VStack {
                    ZStack {
                        Circle()
                            .fill(Color.clear)
                            .background(.ultraThinMaterial)
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                        
                        ProgressView()
                            .tint(Color.white)
                            .progressViewStyle(.circular)
                            .controlSize(.regular)
                    }
                    .padding(.top, 16)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.move(edge: .top))
            }
        }
        .animation(.bouncy, value: store.isRefreshing)
    }
}

// MARK: - Scroll View Offset Observer

extension ArticleScreen {
    struct ScrollViewOffsetObserver: ViewModifier {
        
        let safeAreaTopHeight: CGFloat
        @Binding var navBarOpacity: CGFloat
        @State private var lastValue: CGFloat = .zero
        let onRefreshTriggered: () -> Void
        
        func body(content: Content) -> some View {
            content
                .background(GeometryReader { geometry in
                    Color.clear
                        .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).origin)
                })
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    let percentage = 0.8
                    let adjustedValue = max(0, abs(value.y) - (UIScreen.main.bounds.width * percentage))
                    let coefficient = abs(adjustedValue) / (UIScreen.main.bounds.width * (1 - percentage))
                    let opacity = min(coefficient, 1)
                    if lastValue != opacity {
                        navBarOpacity = opacity
                    }
                    lastValue = opacity
                }
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    if value.y > 0 {
                        onRefreshTriggered()
                    }
                }
        }
        
        struct ScrollOffsetPreferenceKey: PreferenceKey {
            nonisolated(unsafe) static var defaultValue: CGPoint = .zero
            static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {}
        }
    }
}

// MARK: UI Extensions

extension UIApplication {
    var keyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
    
    static var topSafeArea: CGFloat {
        return UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        ArticleScreen(
            store: Store(
                initialState: ArticleFeature.State(
                    articlePreview: .mock,
                    article: .mock
                )
            ) {
                ArticleFeature()
            }
        )
    }
}

#Preview("Test comments") {
    NavigationStack {
        ArticleScreen(
            store: Store(
                initialState: ArticleFeature.State(
                    articlePreview: .mock,
                    commentText: "Test"
                )
            ) {
                ArticleFeature()
            } withDependencies: {
                $0.apiClient.getArticle = { @Sendable _, _ in
                    return AsyncThrowingStream { continuation in
                        continuation.yield(.mockWithComment)
                        Task {
                            try? await Task.sleep(for: .seconds(5))
                            continuation.yield(.mockWithTwoComments)
                        }
                    }
                }
                $0.apiClient.replyToComment = { @Sendable _, _, _ in
                    try? await Task.sleep(for: .seconds(2))
                    return CommentResponseType.success
                }
            }
        )
    }
}
