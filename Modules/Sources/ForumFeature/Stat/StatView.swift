//
//  StatView.swift
//  ForPDA
//
//  Created by Xialtal on 14.06.25.
//

import SwiftUI
import ComposableArchitecture
import Models
import SharedUI

@ViewAction(for: StatFeature.self)
public struct StatView: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<StatFeature>
    @Environment(\.tintColor) private var tintColor
    
    // MARK: - Init
    
    public init(store: StoreOf<StatFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ScrollView {
                if !store.isLoading, let stat = store.stat {
                    VStack(spacing: 0) {
                        VStack {
                            Text(stat.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.bottom, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text(stat.description)
                                .font(.callout)
                                .foregroundStyle(Color(.Labels.secondary))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.bottom, 28)
                        
                        VStack {
                            HStack(spacing: 12) {
                                InformationRow(LocalizedStringKey("Subforums"), .number(stat.subforumsCount))
                                
                                InformationRow(LocalizedStringKey("Topics"), .number(stat.topicsCount))
                            }
                            
                            InformationRow(LocalizedStringKey("Posts"), .number(stat.postsCount))
                            
                            InformationRow(LocalizedStringKey("Moderators"), .moderators(stat.moderators))
                        }
                    }
                    .padding(16)
                    .navigationBarTitleDisplayMode(.inline)
                }
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
    
    // MARK: - Open In Browser Button
    
    @ViewBuilder
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
    
    // MARK: - Row
    
    enum RowType {
        case number(Int)
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
                
            case .moderators(let moderators):
                BrickLayout(verticalSpacing: 6, horizontalSpacing: 8) {
                    ForEach(moderators) { moderator in
                        UserBrickButton(moderator)
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
    
    @ViewBuilder
    private func UserBrickButton(_ moderator: ForumStat.ForumModerator) -> some View {
        Button {
            // TODO: Handle click
        } label: {
            Text(verbatim: "\(moderator.name)")
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
}

// MARK: - Previews

#Preview {
    NavigationStack {
        StatView(
            store: Store(
                initialState: StatFeature.State(
                    forumId: 0
                )
            ) {
                StatFeature()
            }
        )
    }
}
