//
//  PostKarmaHistoryView.swift
//  ForPDA
//
//  Created by Xialtal on 10.04.26.
//

import SwiftUI
import ComposableArchitecture
import Models
import SharedUI
import SFSafeSymbols

@ViewAction(for: PostKarmaHistoryFeature.self)
public struct PostKarmaHistoryView: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<PostKarmaHistoryFeature>
    @Environment(\.tintColor) private var tintColor
    
    // MARK: - Init
    
    public init(store: StoreOf<PostKarmaHistoryFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                List(store.history, id: \.id) { vote in
                    VoteRow(vote)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            ._toolbarTitleDisplayMode(.inline)
            .navigationTitle(Text("Karma History", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        send(.cancelButtonTapped)
                    } label: {
                        if isLiquidGlass {
                            Image(systemSymbol: .xmark)
                        } else {
                            Image(systemSymbol: .xmark)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(Color(.Labels.teritary))
                                .frame(width: 30, height: 30)
                                .background(
                                    Circle()
                                        .fill(Color(.Background.quaternary))
                                        .clipShape(Circle())
                                )
                        }
                    }
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
    
    // MARK: - Vote Row
    
    private func VoteRow(_ vote: PostKarmaVote) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button {
                    send(.userButtonTapped(vote.userId))
                } label: {
                    HStack(spacing: 6) {
                        Text(verbatim: vote.nickname)
                            .foregroundStyle(Color(.Labels.primary))
                        
                        Image(systemSymbol: .chevronRight)
                            .foregroundStyle(Color(.Labels.quaternary))
                    }
                    .font(.callout)
                    .fontWeight(.semibold)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                HStack(spacing: 4) {
                    let color = Color(vote.vote > 0 ? .Main.green : .Main.red)
                    let voteText = vote.vote > 0 ? "+\(vote.vote)" : "\(vote.vote)"
                    Text(verbatim: voteText)
                        .foregroundStyle(color)
                    
                    Image(systemSymbol: vote.arrowSymbol)
                        .foregroundStyle(color)
                }
                .font(.callout)
                .fontWeight(.semibold)
            }
            
            Text(vote.voteDate.formattedDate(), bundle: .module)
                .font(.caption)
                .foregroundStyle(Color(.Labels.quaternary))
        }
    }
}

// MARK: - Extensions

fileprivate extension PostKarmaVote {
    var arrowSymbol: SFSymbol {
        if #available(iOS 17.0, *) {
            return vote > 0 ? .arrowshapeUpFill : .arrowshapeDownFill
        } else {
            return vote > 0 ? .arrowUp : .arrowDown
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        PostKarmaHistoryView(
            store: Store(
                initialState: PostKarmaHistoryFeature.State(
                    postId: 1
                )
            ) {
                PostKarmaHistoryFeature()
            }
        )
    }
}
