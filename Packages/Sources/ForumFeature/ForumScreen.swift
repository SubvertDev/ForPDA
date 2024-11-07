//
//  ForumScreen.swift
//  ForPDA
//
//  Created by Xialtal on 25.10.24.
//

import SwiftUI
import ComposableArchitecture
import SFSafeSymbols
import SharedUI
import Models

public struct ForumScreen: View {
    
    @Perception.Bindable public var store: StoreOf<ForumFeature>
    @Environment(\.tintColor) private var tintColor
    
    public init(store: StoreOf<ForumFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color.Background.primary
                    .ignoresSafeArea()
                
                if let forum = store.forum {
                    List {
                        if !forum.subforums.isEmpty {
                            SubforumsSection(subforums: forum.subforums)
                        }
                        
                        if !forum.announcements.isEmpty {
                            AnnouncmentsSection(announcements: forum.announcements)
                        }

                        if !store.topicsPinned.isEmpty {
                            TopicsSection(topics: store.topicsPinned, pinned: true)
                        }
                        
                        TopicsSection(topics: store.topics, pinned: false)
                    }
                    .scrollContentBackground(.hidden)
                } else {
                    ProgressView().id(UUID())
                }
            }
            .navigationTitle(Text(store.forumName))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Button {
                            // TODO: forum info
                        } label: {
                            Image(systemSymbol: .infoCircle)
                        }
                        
                        Button {
                            store.send(.settingsButtonTapped)
                        } label: {
                            Image(systemSymbol: .gearshape)
                        }
                    }
                }
            }
            .task {
                store.send(.onTask)
            }
        }
    }
    
    // MARK: - Topics
    
    @ViewBuilder
    private func TopicsSection(topics: [TopicInfo], pinned: Bool) -> some View {
        Section {
            ForEach(topics) { topic in
                HStack(spacing: 25) {
                    Row(title: topic.name, unread: topic.isUnread) {
                        store.send(.topicTapped(id: topic.id))
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .buttonStyle(.plain)
                .frame(height: 60)
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        } header: {
            Header(title: pinned ? LocalizedStringKey("Pinned topics") : LocalizedStringKey("Topics"))
        }
        .listRowBackground(Color.Background.teritary)
    }
    
    // MARK: - Subforums section
    
    @ViewBuilder
    private func SubforumsSection(subforums: [ForumInfo]) -> some View {
        Section {
            ForEach(subforums) { forum in
                HStack(spacing: 25) {
                    Row(title: forum.name, unread: forum.isUnread, action: {
                        store.send(.subforumTapped(id: forum.id, name: forum.name))
                    })
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .buttonStyle(.plain)
                .frame(height: 60)
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        } header: {
            Header(title: LocalizedStringKey("Subforums"))
        }
        .listRowBackground(Color.Background.teritary)
    }
    
    // MARK: - Announcements section
    
    @ViewBuilder
    private func AnnouncmentsSection(announcements: [Announcement]) -> some View {
        Section {
            ForEach(announcements) { announcement in
                HStack(spacing: 25) {
                    Row(title: announcement.name, action: {
                        // TODO: announcement page handler
                    })
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .buttonStyle(.plain)
                .frame(height: 60)
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        } header: {
            Header(title: LocalizedStringKey("Announcements"))
        }
        .listRowBackground(Color.Background.teritary)
    }
    
    // MARK: - Row
    
    @ViewBuilder
    private func Row(title: String, unread: Bool = false, action: @escaping () -> Void = {}) -> some View {
        HStack(spacing: 0) { // Hacky HStack to enable tap animations
            Button {
                action()
            } label: {
                HStack(spacing: 0) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(Color.Labels.primary)
                    
                    Spacer(minLength: 8)
                    
                    if unread {
                        Circle()
                            .font(.title2)
                            .foregroundStyle(tintColor)
                            .frame(width: 8)
                            .padding(.trailing, 12)
                    }
                }
            }
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        .buttonStyle(.plain)
        .frame(height: 60)
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private func Header(title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .foregroundStyle(Color.Labels.teritary)
            .textCase(nil)
            .offset(x: 0)
            .padding(.bottom, 4)
    }
    
    @ViewBuilder
    private func Header(title: LocalizedStringKey) -> some View {
        Text(title, bundle: .module)
            .font(.subheadline)
            .foregroundStyle(Color.Labels.teritary)
            .textCase(nil)
            .offset(x: 0)
            .padding(.bottom, 4)
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        ForumScreen(
            store: Store(
                initialState: ForumFeature.State(forum: .mock)
            ) {
                ForumFeature()
            }
        )
    }
}
