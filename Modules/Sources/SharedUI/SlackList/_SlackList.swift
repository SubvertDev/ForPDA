//
//  _SlackList.swift
//  SharedUI
//
//  Created by Ilia Lubianoi on 04.03.2026.
//

import SwiftUI
import SmoothGradient

public enum SlackListRefreshState: Equatable {
    case idle
    case loading
    case loaded
    case error
}

@available(iOS 18, *)
public struct _SlackList<Content: View>: View {
    
    // MARK: - Properties
    
    @State private var offsetY: CGFloat = 0
    @State private var initialValue: CGFloat?
    @State private var backgroundOpacity = 1.0
    @State private var titleOpacity = 1.0
    @State private var refreshTitleOpacity = 0.0
    @State private var hasTriggeredRefreshTitleEnd = false
    @State private var internalRefreshState: SlackListRefreshState = .idle
    
    @State private var discardFirstValue = false
    
    @ViewBuilder private let content: () -> Content
    private let navigationTitle: Text
    private let topBarColor: () -> Color
    private var onRefresh: @Sendable () async throws -> Void = {}
    
    private var iOSVersion: Int {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return version.majorVersion
    }
    
    // MARK: - Inits
    
    public init(
        _ navigationTitle: LocalizedStringResource,
        @ViewBuilder content: @escaping () -> Content,
        topBarColor: @escaping () -> Color = { Color(.Background.teritary) }
    ) {
        self.navigationTitle = Text(navigationTitle)
        self.content = content
        self.topBarColor = topBarColor
    }
    
    public init(
        verbatim navigationTitle: String,
        @ViewBuilder content: @escaping () -> Content,
        topBarColor: @escaping () -> Color = { Color(.Background.teritary) }
    ) {
        self.navigationTitle = Text(verbatim: navigationTitle)
        self.content = content
        self.topBarColor = topBarColor
    }
    
    // MARK: - Body
    
    public var body: some View {
        List {
            content()
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .overlay(alignment: .top) {
            let initial = initialValue ?? 0
            Text("Refreshing...", bundle: .module)
                .font(.subheadline.monospaced())
                .offset(y: abs(offsetY - initial) + initial)
                .opacity(refreshTitleOpacity)
        }
        .overlay(alignment: .top) {
            if internalRefreshState != .idle {
                let initial = initialValue ?? 0
                RefreshStateLine(state: internalRefreshState)
                    .offset(y: -(offsetY - initial))
                    .opacity(backgroundOpacity)
            }
        }
        .if(iOSVersion == 26) { view in
            let initial = initialValue ?? 0
            view
                .background(alignment: .top) {
                    // Static part
                    Color.clear
                        .frame(height: 0)
                        .background {
                            topBarColor()
                                .ignoresSafeArea(edges: .top)
                                .offset(y: min(0, -(offsetY - initial)))
                                .opacity(backgroundOpacity)
                        }
                }
                .background(alignment: .top) {
                    // Moving part
                    topBarColor()
                        .frame(height: max(0, -(offsetY - initial)))
                }
                .background {
                    Color(.Background.primary)
                        .ignoresSafeArea()
                }
        }
        .if(iOSVersion == 18) { view in
            view
                .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
                .overlay(alignment: .top) {
                    // Pseudo-blur
                    Color.clear
                        .frame(height: 0)
                        .background {
                            LinearGradient(
                                gradient: .smooth(
                                    from: .white,
                                    to: .white.opacity(0),
                                    curve: .circularEaseIn
                                ),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .ignoresSafeArea(edges: .top)
                        }
                }
                .overlay(alignment: .top) {
                    // Static part
                    Color.clear
                        .frame(height: 0)
                        .background {
                            topBarColor()
                                .ignoresSafeArea(edges: .top)
                                .opacity(backgroundOpacity)
                        }
                }
                .background(alignment: .top) {
                    // Moving part
                    topBarColor()
                        .frame(height: max(0, -(offsetY - (initialValue ?? 0))))
                }
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y
        } action: { oldValue, newValue in
            if oldValue != newValue {
                offsetY = newValue
            }
        }
        .onChange(of: offsetY) {
            if iOSVersion == 18, !discardFirstValue {
                discardFirstValue = true
                return
            }
            // print(offsetY)
            if initialValue == nil {
                initialValue = offsetY
            }
            if let initialValue {
                let backgroundFactor = iOSVersion == 26 ? 1.4 : 1.225
                let start = initialValue / backgroundFactor
                let normalized = (offsetY - start) / (initialValue - start)
                backgroundOpacity = Double(min(max(normalized, 0), 1))
                
                let titleStart = initialValue * 0.875
                let titleNormalized = (offsetY - titleStart) / (initialValue - titleStart)
                titleOpacity = Double(min(max(titleNormalized, 0), 1))
                
                let refreshTitleStart = initialValue * 1.8
                let refreshTitleEnd = initialValue * 2.2 // 2.5
                let refreshTitleNormalized = (offsetY - refreshTitleStart) / (refreshTitleEnd - refreshTitleStart)
                refreshTitleOpacity = Double(min(max(refreshTitleNormalized, 0), 1))
                
                if offsetY <= refreshTitleEnd, !hasTriggeredRefreshTitleEnd {
                    hasTriggeredRefreshTitleEnd = true
                    handleRefreshTitleEndReached()
                } else if offsetY > refreshTitleEnd {
                    hasTriggeredRefreshTitleEnd = false
                }
            }
        }
        ._scrollEdgeEffectHidden(backgroundOpacity != 0, for: .top)
        .toolbarTitleDisplayMode(.inlineLarge)
        .toolbar {
            ToolbarItem(placement: .title) {
                Group {
                    navigationTitle + Text("".toolbarFix())
                }
                .font(.title.bold())
                .opacity(titleOpacity)
            }
        }
        .sensoryFeedback(.impact, trigger: sensoryTrigger)
    }
    
    @State private var sensoryTrigger = false
    
    // MARK: - Functions
    
    private func handleRefreshTitleEndReached() {
        guard internalRefreshState != .loading else { return }
        Task {
            await performRefresh()
        }
    }
    
    private func setRefreshState(_ state: SlackListRefreshState) {
        internalRefreshState = state
    }
    
    @MainActor
    private func performRefresh() async {
        sensoryTrigger.toggle()
        setRefreshState(.loading)
        do {
            try await onRefresh()
            setRefreshState(.loaded)
        } catch {
            setRefreshState(.error)
        }
        
        try? await Task.sleep(for: .seconds(2))
        if internalRefreshState == .loaded || internalRefreshState == .error {
            setRefreshState(.idle)
        }
    }
}

@available(iOS 18, *)
extension _SlackList {
    public func onRefresh(
        _ action: @escaping @Sendable () async throws -> Void
    ) -> Self {
        var copy = self
        copy.onRefresh = action
        return copy
    }
}

// MARK: - Extensions

extension String {
    func toolbarFix() -> String {
        return self + String(repeating: " ", count: 100)
    }
}

// MARK: - Previews

@available(iOS 18, *)
#Preview {
    NavigationStack {
        _SlackList(verbatim: "Favorites") {
            ForEach(0..<100) { index in
                Text(String(index))
            }
        }
        .onRefresh {
            try await Task.sleep(for: .seconds(Double.random(in: 2...4)))
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Text(verbatim: "?")
            }
        }
    }
}
