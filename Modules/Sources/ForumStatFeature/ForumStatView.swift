//
//  ForumStatView.swift
//  ForPDA
//
//  Created by Xialtal on 14.06.25.
//

import SwiftUI
import ComposableArchitecture
import Models
import SharedUI

@ViewAction(for: ForumStatFeature.self)
public struct ForumStatView: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<ForumStatFeature>
    @Environment(\.tintColor) private var tintColor
    
    // MARK: - Init
    
    public init(store: StoreOf<ForumStatFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ScrollView {
                VStack(spacing: 0) {
                    if !store.isLoading {
                        switch store.type {
                        case .forum:
                            if let stat = store.stat {
                                ForumStat(stat)
                            }
                        case .topic(let topic):
                            TopicStat(topic)
                        }
                    }
                }
                .padding(16)
                .navigationBarTitleDisplayMode(.inline)
            }
            .sheet(item: $store.scope(state: \.destination?.share, action: \.destination.share)) { rawUrl in
                ShareActivityView(url: rawUrl.withState { $0 }) { _ in
                    send(.linkShared)
                }
                .presentationDetents([.medium])
            }
            .background(Color(.Background.primary))
            .safeAreaInset(edge: .bottom) {
                OpenInBrowserButton()
            }
            .toolbar {
                Toolbar()
            }
            .overlay {
                if store.isLoading, store.stat == nil {
                    PDALoader()
                        .frame(width: 24, height: 24)
                }
            }
            .onAppear {
                send(.onAppear)
            }
        }
    }
    
    // MARK: - Forum Stat
    
    @ViewBuilder
    private func ForumStat(_ stat: ForumStat) -> some View {
        Header(name: stat.name, description: stat.description)
        
        VStack {
            HStack(spacing: 12) {
                InformationRow(LocalizedStringKey("Subforums"), .number(stat.subforumsCount))
                
                InformationRow(LocalizedStringKey("Topics"), .number(stat.topicsCount))
            }
            
            InformationRow(LocalizedStringKey("Posts"), .number(stat.postsCount))
            
            InformationRow(LocalizedStringKey("Moderators"), .moderators(stat.moderators))
        }
    }
    
    // MARK: - Topic Stat
    
    @ViewBuilder
    private func TopicStat(_ topic: Topic) -> some View {
        Header(name: topic.name, description: topic.description)
        
        VStack {
            HStack(spacing: 12) {
                InformationRow(LocalizedStringKey("Created At"), .text(topic.createdAt.formatted()))
                
                InformationRow(LocalizedStringKey("Author"), .text(topic.authorName))
            }
            
            HStack(spacing: 12) {
                let curator: RowType = if topic.curatorId == 0 {
                    .localizedText(LocalizedStringKey("no"))
                } else {
                    .text(topic.curatorName)
                }
                InformationRow(LocalizedStringKey("Curator"), curator)
                
                InformationRow(
                    LocalizedStringKey("Status"),
                    .localizedText(topic.isClosed ? LocalizedStringKey("Closed") : LocalizedStringKey("Open"))
                )
            }
            
            if store.isUserAuthorized {
                if let viewers = store.topicViewers, !store.isLoading {
                    TopicViewers(viewers)
                } else {
                    PDALoader()
                        .frame(width: 24, height: 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 28)
                }
            }
        }
    }
    
    @ViewBuilder
    private func TopicViewers(_ viewers: TopicViewers) -> some View {
        VStack {
            Group {
                Text("Reading this topic: **\(viewers.allCount) people**", bundle: .module)
                
                Text("Guests: **\(viewers.guestsCount)**", bundle: .module)
                
                Text("Hidden users: **\(viewers.hiddenUsersCount)**", bundle: .module)
            }
            .font(.footnote)
            .foregroundStyle(Color(.Labels.secondary))
            .frame(maxWidth: .infinity, alignment: .leading)
            
            BrickLayout(verticalSpacing: 6, horizontalSpacing: 8) {
                ForEach(viewers.users) { user in
                    UserBrickButton(id: user.id, name: user.name)
                }
            }
            .padding(.top, 12)
        }
        .padding(.top, 18)
    }
    
    // MARK: - Open In Browser Button
    
    private func OpenInBrowserButton() -> some View {
        Button {
            send(.openInBrowserButtonTapped)
        } label: {
            HStack {
                Text(verbatim: store.shareLink)
                    .font(.footnote)
                    .foregroundStyle(Color(.Labels.teritary))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemSymbol: .arrowUpRight)
                    .font(.callout)
                    .foregroundStyle(tintColor)
            }
        }
        .padding(16)
    }
    
    // MARK: - Header
    
    private func Header(name: String, description: String) -> some View {
        VStack {
            Text(name)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(description)
                .font(.callout)
                .foregroundStyle(Color(.Labels.secondary))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.bottom, 28)
    }
    
    // MARK: - Row
    
    enum RowType {
        case number(Int)
        case text(String)
        case localizedText(LocalizedStringKey)
        case moderators([ForumStat.ForumModerator])
    }
    
    private func InformationRow(_ header: LocalizedStringKey, _ content: RowType) -> some View {
        VStack(spacing: 2) {
            Text(header, bundle: .module)
                .font(.footnote)
                .foregroundStyle(Color(.Labels.teritary))
            
            switch content {
            case .number(let content):
                Text(content, format: .number)
                    .font(.body)
                    .multilineTextAlignment(.center)
                
            case .text(let content):
                Text(verbatim: content)
                    .font(.body)
                    .multilineTextAlignment(.center)
                
            case .localizedText(let content):
                Text(content, bundle: .module)
                    .font(.body)
                    .multilineTextAlignment(.center)
                
            case .moderators(let moderators):
                BrickLayout(verticalSpacing: 6, horizontalSpacing: 8) {
                    ForEach(moderators) { moderator in
                        UserBrickButton(id: moderator.id, name: moderator.name)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(12)
        .background(
            Color(.Background.teritary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        )
    }
    
    // MARK: - User Brick Button
    
    @ViewBuilder
    private func UserBrickButton(id: Int, name: String) -> some View {
        Button {
            send(.userButtonTapped(id))
        } label: {
            Text(verbatim: "\(name)")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(tintColor)
        }
        .buttonStyle(.plain)
        .padding(.vertical, 9)
        .padding(.horizontal, 8)
        .background(
            Color(.Background.teritary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        )
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                send(.closeButtonTapped)
            } label: {
                if isLiquidGlass {
                    Image(systemSymbol: .xmark)
                } else {
                    Text("Close", bundle: .module)
                }
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                send(.shareLinkButtonTapped)
            } label: {
                Image(systemSymbol: .squareAndArrowUp)
            }
        }
    }
}

// MARK: - Previews

#Preview("Forum Stat") {
    NavigationStack {
        ForumStatView(
            store: Store(
                initialState: ForumStatFeature.State(
                    type: .forum(id: 0)
                )
            ) {
                ForumStatFeature()
            }
        )
    }
}

#Preview("Topic Stat") {
    NavigationStack {
        ForumStatView(
            store: Store(
                initialState: ForumStatFeature.State(
                    type: .topic(.mock)
                )
            ) {
                ForumStatFeature()
            }
        )
    }
}
