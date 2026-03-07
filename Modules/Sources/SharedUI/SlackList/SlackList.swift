//
//  SlackList.swift
//  SharedUI
//
//  Created by Ilia Lubianoi on 05.03.2026.
//

import SwiftUI

public struct SlackList<Content: View>: View {
    
    // MARK: - Properties
    
    private let navigationTitle: LocalizedStringResource
    @ViewBuilder private let content: () -> Content
    private var onRefresh: @Sendable () async throws -> Void = {}
    
    // MARK: - Init
    
    public init(
        _ navigationTitle: LocalizedStringResource,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.navigationTitle = navigationTitle
        self.content = content
    }
    
    // MARK: - Body
    
    public var body: some View {
        if #available(iOS 18, *) {
            let onRefresh = self.onRefresh
            _SlackList(
                navigationTitle,
                content: content
            )
            .onRefresh {
                try await onRefresh()
            }
        } else {
            List {
                content()
            }
            .navigationTitle(navigationTitle)
            ._toolbarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Modifiers

extension SlackList {
    public func onRefresh(
        _ action: @escaping @Sendable () async throws -> Void
    ) -> Self {
        var copy = self
        copy.onRefresh = action
        return copy
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        SlackList("Preview") {
            Section {
                TopicRow(
                    title: .plain("ForPDA [iOS]"),
                    date: .now,
                    username: "subvertd",
                    isClosed: false,
                    isUnread: false,
                    onAction: { _ in }
                )
                .listRowBackground(
                    Color(.Background.teritary))
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            } header: {
                Text("section")
            }
        }
        .refreshable {
            try? await Task.sleep(for: .seconds(Double.random(in: 2...4)))
        }
    }
}
