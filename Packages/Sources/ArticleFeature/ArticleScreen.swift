//
//  NewsScreen.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import SwiftUI
import ComposableArchitecture
import NukeUI
import SFSafeSymbols
import YouTubePlayerKit
import Models
import SharedUI
import SkeletonUI

extension UINavigationController: UIGestureRecognizerDelegate {
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
    
    public init(store: StoreOf<ArticleFeature>) {
        self.store = store
    }
    
    @State private var scrollViewContentHeight: CGFloat = 0
    @State private var safeAreaTopHeight: CGFloat = 0
    @State private var navBarOpacity: CGFloat = 0
    private var navBarFullyVisible: Bool {
        return navBarOpacity >= 1
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ArticleScrollView()
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden()
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbar {
                    ToolbarButton(placement: .topBarLeading, symbol: .chevronLeft) {
                        store.send(.backButtonTapped)
                    }
                    ToolbarButton(placement: .topBarTrailing, symbol: .bookmark) {}
                    ToolbarButton(placement: .topBarTrailing, symbol: .ellipsis) {}
                }
                .overlay(alignment: .top) {
                    Color.Background.primaryAlpha
                        .opacity(navBarOpacity)
                        .frame(width: UIScreen.main.bounds.width, height: safeAreaTopHeight)
                        .ignoresSafeArea()
                }
                .background(GeometryReader { proxy in
                    Color.clear
                        .task(id: proxy.size.width) {
                            safeAreaTopHeight = proxy.safeAreaInsets.top
                            print(safeAreaTopHeight)
                        }
                })
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
                ArticleHeader()
                
                if store.isLoading {
                    ArticleLoader()
                } else if let elements = store.elements, let comments = store.article?.comments {
                    ArticleView(store: store, elements: elements, comments: comments)
                }
            }
            .modifier(
                ScrollViewOffsetObserver(
                    scrollViewContentHeight: $scrollViewContentHeight,
                    navBarOpacity: $navBarOpacity
                )
            )
        }
        .scrollIndicators(.hidden)
        .ignoresSafeArea(.all, edges: .top)
        .coordinateSpace(name: "scroll")
    }
    
    // MARK: - Article Header
    
    @ViewBuilder
    private func ArticleHeader() -> some View {
        ZStack {
            ZStack {
                Rectangle()
                    .background(Color.Background.forcedDark)
                
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
                .overlay(alignment: .bottom) {
                    LinearGradient(
                        gradient: Gradient(
                            colors: [
                                Color.Background.forcedDark.opacity(0),
                                Color.Background.forcedDark.opacity(0.5),
                                Color.Background.forcedDark.opacity(0.7),
                                Color.Background.forcedDark.opacity(0.9),
                                Color.Background.forcedDark,
                                Color.Background.forcedDark,
                                Color.Background.forcedDark,
                                Color.Background.forcedDark
                            ]
                        ),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 124)
                }
            }
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
            .clipped()
            
            VStack(spacing: 0) {
                Spacer()
                
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
            .padding()
        }
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
        }
    }
    
    // MARK: - Article Loader
    
    @ViewBuilder
    private func ArticleLoader() -> some View {
        Spacer()
            .frame(height: UIScreen.main.bounds.height * 0.2)
        
        VStack {
            ModernCircularLoader()
                .frame(width: 24, height: 24)
            
            Text("Loading article...", bundle: .module)
        }
    }
}

// MARK: - Scroll View Offset Observer

extension ArticleScreen {
    struct ScrollViewOffsetObserver: ViewModifier {
        
        @Binding var scrollViewContentHeight: CGFloat
        @Binding var navBarOpacity: CGFloat
        
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
                    navBarOpacity = opacity
                }
        }
        
        struct ScrollOffsetPreferenceKey: PreferenceKey {
            nonisolated(unsafe) static var defaultValue: CGPoint = .zero
            static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {}
        }
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
