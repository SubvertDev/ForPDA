//
//  ForumScreen.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 02.09.2024.
//

import SwiftUI
import ComposableArchitecture
import SFSafeSymbols
import SharedUI

@ViewAction(for: ForumsListFeature.self)
public struct ForumsListScreen: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<ForumsListFeature>
    @Environment(\.tintColor) private var tintColor
    
    // MARK: - Init
    
    public init(store: StoreOf<ForumsListFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                if let forums = store.forums {
                    List(forums, id: \.id) { forumRow in
                        WithPerceptionTracking {
                            Section {
                                if store.isExpanded[forumRow.id]! {
                                    ForEach(forumRow.forums) { forum in
                                        ForumRow(
                                            title: forum.name,
                                            isUnread: forum.isUnread,
                                            onAction: {
                                                if let redirectUrl = forum.redirectUrl {
                                                    send(.forumRedirectTapped(redirectUrl))
                                                } else {
                                                    send(.forumTapped(id: forum.id, name: forum.name))
                                                }
                                            }
                                        )
                                    }
                                    
                                }
                            } header: {
                                Header(forumRow: forumRow)
                            }
                            .listRowBackground(Color(.Background.teritary))
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .animation(.easeInOut(duration: 0.3), value: store.isExpanded)
                } else {
                    PDALoader()
                        .frame(width: 24, height: 24)
                }
            }
            .animation(.default, value: store.forums)
            .navigationTitle(Text("Forum", bundle: .module))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        send(.settingsButtonTapped)
                    } label: {
                        Image(systemSymbol: .gearshape)
                    }
                }
            }
            .onAppear {
                send(.onAppear)
            }
        }
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private func Header(forumRow: ForumRowInfo) -> some View {
        Button {
            send(.forumSectionExpandTapped(forumRow.id))
        } label: {
            HStack(spacing: 0) {
                Text(forumRow.title)
                    .font(.subheadline)
                    .foregroundStyle(Color(.Labels.teritary))
                    .textCase(nil)
                    .offset(x: -16)
                
                Spacer()
                Image(systemSymbol: .chevronUp)
                    .font(.body)
                    .foregroundStyle(Color(.Labels.quaternary))
                    .rotationEffect(.degrees(store.isExpanded[forumRow.id]! ? 0 : -180))
                    .offset(x: 16)
            }
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        ForumsListScreen(
            store: Store(
                initialState: ForumsListFeature.State()
            ) {
                ForumsListFeature()
            }
        )
    }
}
