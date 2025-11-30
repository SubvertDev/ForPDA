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
import Models
import SharedUI
import SkeletonUI
import SmoothGradient

public struct ArticleScreen: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<ArticleFeature>
    @FocusState public var focus: ArticleFeature.State.Field?
    @Environment(\.tintColor) private var tintColor
    
    @State private var scrollProxy: ScrollViewProxy?
    @State private var safeAreaTopHeight: CGFloat
    @State private var navBarOpacity: CGFloat = 0
    @State private var isCommentsViewVisible = false
    @State private var isCommentViewExpanded = false
    private var navBarFullyVisible: Bool {
        return navBarOpacity >= 1
    }
    
    // MARK: - Init
    
    public init(store: StoreOf<ArticleFeature>) {
        self.store = store
        self.safeAreaTopHeight = UIApplication.topSafeArea + 44 + (isLiquidGlass ? 10 : 0)
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ArticleScrollView()
                .bind($store.focus, to: $focus)
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
                .safeAreaInset(edge: .bottom) { Keyboard() }
                ._scrollEdgeEffectHidden(!isCommentViewExpanded, for: .bottom)
                .onTapGesture { focus = nil }
                .modifier(NavigationBarSettings())
                .toolbar { Toolbar() }
                .overlay(alignment: .top) {
                    if !isLiquidGlass {
                        ToolbarOverlay()
                    }
                }
                .overlay { RefreshIndicator() }
                .background(Color(.Background.primary))
                .onAppear { store.send(.onAppear) }
        }
    }
    
    // MARK: - Keyboard
    
    @ViewBuilder
    private func Keyboard() -> some View {
        WithPerceptionTracking {
            Group {
                if #available(iOS 26.0, *) {
                    LiquidKeyboardView(
                        store: store,
                        focus: $focus,
                        isExpanded: $isCommentViewExpanded,
                        isScrollDownVisible: $isCommentsViewVisible.inverted
                    ) {
                        withAnimation { scrollProxy?.scrollTo(69, anchor: .top) }
                    }
                } else {
                    KeyboardView(
                        store: store,
                        focus: $focus,
                        isScrollDownVisible: $isCommentsViewVisible.inverted
                    ) {
                        withAnimation { scrollProxy?.scrollTo(69, anchor: .top) }
                    }
                    .transition(.push(from: .bottom))
                }
            }
            .animation(isLiquidGlass ? .bouncy : .default, value: store.canComment)
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private func Toolbar() -> some ToolbarContent {
        if #available(iOS 26.0, *) {
            // default system back button
            ToolbarSpacer(.fixed)
        } else {
            ToolbarItem(placement: .topBarLeading) {
                ToolbarButton(placement: .topBarLeading, symbol: .chevronLeft) {
                    store.send(.backButtonTapped)
                }
            }
        }
        
        ToolbarItemGroup(placement: .topBarTrailing) {
            HStack(spacing: 8) {
//                ToolbarButton(placement: .topBarTrailing, symbol: .bookmark) {
//                    store.send(.bookmarkButtonTapped)
//                }
                
                ArticleMenu(store: store, isDark: navBarFullyVisible)
            }
        }
    }
    
    // MARK: - Toolbar Overlay (Pre 26)
    
    @available(iOS, deprecated: 26.0)
    @ViewBuilder
    private func ToolbarOverlay() -> some View {
        Color(.Background.primaryAlpha)
            .background(.ultraThinMaterial)
            .opacity(navBarOpacity)
            .frame(width: UIScreen.main.bounds.width, height: safeAreaTopHeight)
            .ignoresSafeArea()
    }
    
    // MARK: - Scroll View
    
    @ViewBuilder
    private func ArticleScrollView() -> some View {
        ScrollViewReader { proxy in
            WithPerceptionTracking {
                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        ParallaxHeader(
                            coordinateSpace: "scroll",
                            defaultHeight: UIScreen.main.bounds.width,
                            safeAreaTopHeight: safeAreaTopHeight
                        ) {
                            WithPerceptionTracking {
                                ArticleHeader()
                            }
                        }
                        
                        if store.isLoading {
                            ArticleLoader()
                                .padding(.top, 32)
                            
                        } else if let elements = store.elements {
                            ArticleView(elements: elements)
                                .background(Color(.Background.primary))
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
                .onAppear {
                    scrollProxy = proxy
                }
            }
        }
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
                        Color(.Background.forcedDark)
                    }
                }
                .skeleton(
                    with: state.isLoading,
                    appearance: .gradient(
                        .linear,
                        color: Color(.Labels.forcedLight).opacity(0.25),
                        background: Color(.Background.forcedDark),
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
                        .foregroundStyle(Color(.Labels.forcedLight))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 8)
                    
                    HStack {
                        Text(store.articlePreview.authorName)
                        Spacer()
                        Text(store.articlePreview.formattedDate, bundle: .module)
                    }
                    .font(.caption)
                    .foregroundStyle(Color(.Labels.secondaryInvariably))
                }
                .padding(.top, 32)
                .padding(16)
                .background(
                    LinearGradient(
                        gradient: .smooth(
                            from: .clear,
                            to: Color(.Background.forcedDark),
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
                        ArticleElementView(
                            element: element,
                            isShowingVoteResults: store.isShowingVoteResults,
                            isUploadingPollVote: store.isUploadingPollVote,
                            onPollVoteButtonTapped: { id, selections in
                                store.send(.pollVoteButtonTapped(id, selections))
                            },
                            onLinkInTextTapped: { url in
                                store.send(.linkInTextTapped(url))
                            }
                        )
                        .padding(.vertical, 10)
                    }
                }
            }
            .padding(.vertical, 14)
            
            Rectangle()
                .frame(maxWidth: .infinity, maxHeight: 16)
                .foregroundStyle(Color(.Background.teritary))
            
            CommentsView(store: store)
                .modifier(ScrollVisibility(threshold: 0.01, isVisible: $isCommentsViewVisible))
                .id(69)
        }
    }
    
    struct ScrollVisibility: ViewModifier {
        
        let threshold: Double
        @Binding var isVisible: Bool
        
        func body(content: Content) -> some View {
            if #available(iOS 18.0, *) {
                content
                    .onScrollVisibilityChange(threshold: threshold) { value in
                        isVisible = value
                    }
            } else {
                content
            }
        }
    }
    
    // MARK: - Navigation Bar Settings
    
    struct NavigationBarSettings: ViewModifier {
        func body(content: Content) -> some View {
            if #available(iOS 26.0, *) {
                content
                    .toolbarTitleDisplayMode(.inline)
            } else {
                content
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden()
                    .toolbarBackground(.hidden, for: .navigationBar)
            }
        }
    }
    
    // MARK: - Toolbar Button
    
    private func ToolbarButton(
        placement: ToolbarItemPlacement,
        symbol: SFSymbol,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            Image(systemSymbol: symbol)
                .font(.body)
                .foregroundStyle(navBarButtonForegroundStyle())
                .scaleEffect(isLiquidGlass ? 1 : 0.8)
                .background {
                    if !isLiquidGlass {
                        Circle()
                            .fill(Color.clear)
                            .background(.ultraThinMaterial)
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                    }
                }
        }
        .animation(.default, value: navBarFullyVisible)
    }
    
    @available(iOS, deprecated: 26.0)
    func navBarButtonForegroundStyle() -> AnyShapeStyle {
        if isLiquidGlass {
            return AnyShapeStyle(.foreground)
        } else if navBarFullyVisible {
            return AnyShapeStyle(Color(.Labels.teritary))
        } else {
            return AnyShapeStyle(Color(.Labels.primaryInvariably))
        }
    }
    
    // MARK: - Article Loader
    
    @ViewBuilder
    private func ArticleLoader() -> some View {
        VStack {
            PDALoader()
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
                            .refreshClearBackground()
                            .frame(
                                width: isLiquidGlass ? 40 : 32,
                                height: isLiquidGlass ? 40 : 32
                            )
                            .clipShape(Circle())
                        
                        ProgressView()
                            .tint(.primary)
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
                    if #available(iOS 26.0, *) {
                        // skip since navBarOpacity is not used on 26+
                    } else {
                        MainActor.assumeIsolated {
                            let percentage = 0.8
                            let adjustedValue = max(0, abs(value.y) - (UIScreen.main.bounds.width * percentage))
                            let coefficient = abs(adjustedValue) / (UIScreen.main.bounds.width * (1 - percentage))
                            let opacity = min(coefficient, 1)
                            if lastValue != opacity {
                                navBarOpacity = opacity
                            }
                            lastValue = opacity
                        }
                    }
                }
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    MainActor.assumeIsolated {
                        if value.y > 0 {
                            onRefreshTriggered()
                        }
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

// MARK: - Modifiers

struct RefreshClearBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular)
        } else {
            content
                .background(.ultraThinMaterial)
        }
    }
}

extension View {
    func refreshClearBackground() -> some View {
        modifier(RefreshClearBackgroundModifier())
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        ArticleScreen(
            store: Store(
                initialState: ArticleFeature.State(articlePreview: .mock)
            ) {
                ArticleFeature()
            } withDependencies: {
                $0.apiClient.getArticle = { @Sendable _, _ in
                    return AsyncThrowingStream { continuation in
                        Task {
                            try? await Task.sleep(for: .seconds(1))
                            continuation.yield(.mock)
                        }
                    }
                }
            }
        )
    }
    .environment(\.tintColor, Color(.Theme.primary))
}

#Preview("Infinite loading") {
    NavigationStack {
        ArticleScreen(
            store: Store(
                initialState: ArticleFeature.State(articlePreview: .mock)
            ) {
                ArticleFeature()
            } withDependencies: {
                $0.apiClient.getArticle = { @Sendable _, _ in return try await Task.never() }
            }
        )
    }
    .environment(\.tintColor, Color(.Theme.primary))
}

#Preview("Test comments") {
    @Shared(.userSession) var userSession
    $userSession.withLock { $0 = UserSession.mock }
    
    return NavigationStack {
        ArticleScreen(
            store: Store(
                initialState: ArticleFeature.State(
                    articlePreview: .mock,
                    commentText: ""
                )
            ) {
                ArticleFeature()
            } withDependencies: {
                $0.apiClient.getArticle = { @Sendable _, _ in
                    return AsyncThrowingStream { continuation in
                        continuation.yield(.mockWithComment)
                        Task {
                            try? await Task.sleep(for: .seconds(2))
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
    .environment(\.tintColor, Color(.Theme.scarlet))
}
