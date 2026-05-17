//
//  ForumEventLogScreen.swift
//  ForPDA
//
//  Created by Xialtal on 14.05.26.
//

import SwiftUI
import ComposableArchitecture
import Models
import SharedUI
import BBBuilder

@ViewAction(for: ForumEventLogFeature.self)
public struct ForumEventLogScreen: View {
    
    @Perception.Bindable public var store: StoreOf<ForumEventLogFeature>
    @Environment(\.tintColor) private var tintColor
    
    public init(store: StoreOf<ForumEventLogFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                List(store.eventLog, id: \.self) { event in
                    EventRow(event)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            ._toolbarTitleDisplayMode(.inline)
            .navigationTitle(Text(navigationTitleText(), bundle: .module))
            .toolbar {
                ToolbarItem {
                    OptionsMenu()
                }
            }
            .overlay {
                if store.isLoading {
                    PDALoader()
                        .frame(width: 24, height: 24)
                }
            }
            .onAppear {
                send(.onAppear)
            }
        }
    }
    
    // MARK: - Options Menu
    
    @ViewBuilder
    private func OptionsMenu() -> some View {
        WithPerceptionTracking {
            Menu {
                Section {
                    let text = switch store.type {
                    case .post:  LocalizedStringResource("Go to Post", bundle: .module)
                    case .topic: LocalizedStringResource("Go to Topic", bundle: .module)
                    }
                    ContextButton(text: text, symbol: .chevronRight2) {
                        send(.contextMenu(.goToSubject))
                    }
                }
                
                ContextButton(text: LocalizedStringResource("Copy Link", bundle: .module), symbol: .docOnDoc) {
                    send(.contextMenu(.copyLink))
                }
            } label: {
                Image(systemSymbol: .ellipsisCircle)
            }
        }
    }
    
    // MARK: - Event Row
    
    private func EventRow(_ event: ForumEventLog) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button {
                    send(.userButtonTapped(event.userId))
                } label: {
                    HStack(spacing: 6) {
                        Text(verbatim: event.userName)
                            .foregroundStyle(Color(.Labels.primary))
                        
                        Image(systemSymbol: .chevronRight)
                            .foregroundStyle(Color(.Labels.quaternary))
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(verbatim: event.createdAt.formatted())
                    .font(.caption)
                    .foregroundStyle(Color(.Labels.quaternary))
            }
            
            if let content = event.contentAttributed {
                RichText(text: content, isSelectable: true, onUrlTap: { url in
                    send(.urlTapped(url))
                })
            } else {
                Text(verbatim: event.content)
                    .font(.subheadline)
            }
        }
        .listRowBackground(Color.clear)
    }
    
    // MARK: - Helpers
    
    private func navigationTitleText() -> LocalizedStringKey {
        return switch store.type {
        case .post:  "Post History \(String(store.id))"
        case .topic: "Topic History \(String(store.id))"
        }
    }
}

// MARK: - Extensions

extension ForumEventLog {
    var contentAttributed: NSAttributedString? {
        guard !content.isEmpty else { return nil }
        return BBRenderer(baseAttributes: [.font: UIFont.preferredFont(forTextStyle: .callout)])
            .render(text: content)
    }
}

// MARK: - Previews

#Preview("Post Events") {
    NavigationStack {
        ForumEventLogScreen(
            store: Store(
                initialState: ForumEventLogFeature.State(
                    id: 0,
                    type: .post
                )
            ) {
                ForumEventLogFeature()
            }
        )
    }
}

#Preview("Topic Events") {
    NavigationStack {
        ForumEventLogScreen(
            store: Store(
                initialState: ForumEventLogFeature.State(
                    id: 0,
                    type: .topic
                )
            ) {
                ForumEventLogFeature()
            }
        )
    }
}
