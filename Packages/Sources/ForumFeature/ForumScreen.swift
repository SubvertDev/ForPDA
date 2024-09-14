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

public struct ForumScreen: View {
    
    @Perception.Bindable public var store: StoreOf<ForumFeature>
    @Environment(\.tintColor) private var tintColor
    
    public init(store: StoreOf<ForumFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 0) {
                ComingSoonTape()
                    .rotationEffect(Angle(degrees: 12))
                    .padding(.bottom, 100)
                
                ForumIsInDevelopment()
                
                ComingSoonTape()
                    .rotationEffect(Angle(degrees: -20))
                    .padding(.top, 80)
            }
            .navigationTitle(Text("Forum", bundle: .module))
            .navigationBarTitleDisplayMode(.large)
            .task {
                store.send(.onTask)
            }
        }
    }
    
    // MARK: - Empty Screen
    
    @ViewBuilder
    private func ForumIsInDevelopment() -> some View {
        VStack(spacing: 0) {
            Image(systemSymbol: .bubbleLeftAndBubbleRight)
                .font(.title)
                .foregroundStyle(tintColor)
                .frame(width: 48, height: 48)
                .padding(.bottom, 8)
            
            Text("Forum is coming soon", bundle: .module)
                .font(.title3)
                .bold()
                .foregroundColor(Color.Labels.primary)
                .padding(.bottom, 6)
            
            Text("While it is in development, you can stay tuned for updates in our telegram chat", bundle: .module)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.Labels.teritary)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.7)
        }
    }
    
    // MARK: - Coming Soon Tape
    
    @ViewBuilder
    private func ComingSoonTape() -> some View {
        HStack(spacing: 8) {
            ForEach(0..<6, id: \.self) { index in
                Text("COMING SOON", bundle: .module)
                    .font(.footnote)
                    .foregroundStyle(Color.Labels.primaryInvariably)
                    .fixedSize(horizontal: true, vertical: false)
                    .lineLimit(1)
            }
        }
        .frame(width: UIScreen.main.bounds.width * 2, height: 26)
        .background(tintColor)
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        ForumScreen(
            store: Store(
                initialState: ForumFeature.State()
            ) {
                ForumFeature()
            }
        )
    }
}
