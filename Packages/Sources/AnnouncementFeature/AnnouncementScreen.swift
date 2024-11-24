//
//  AnnouncementScreen.swift
//  ForPDA
//
//  Created by Xialtal on 24.11.24.
//

import SwiftUI
import ComposableArchitecture
import PageNavigationFeature
import TopicFeature
import SFSafeSymbols
import SharedUI
import Models

public struct AnnouncementScreen: View {
    
    @Perception.Bindable public var store: StoreOf<AnnouncementFeature>
    @Environment(\.tintColor) private var tintColor
    
    public init(store: StoreOf<AnnouncementFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color.Background.primary
                    .ignoresSafeArea()
                
                if let announcement = store.announcement {
                    List {
                        AnnouncementBody(announcement)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .overlay {
                if store.announcement == nil || store.isLoading {
                    PDALoader()
                        .frame(width: 24, height: 24)
                }
            }
            .navigationTitle(Text(store.announcementName))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                // TODO: Announcement Info?
            }
            .task {
                store.send(.onTask)
            }
        }
    }
    
    // MARK: - Announcement Body
    
    @ViewBuilder
    private func AnnouncementBody(_ announcement: Announcement) -> some View {
        VStack(spacing: 0) {
            ForEach(store.types, id: \.self) { main in
                ForEach(main, id: \.self) { type in
                    TopicView(type: type, attachments: []) // TODO: attachments
                }
            }
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        AnnouncementScreen(
            store: Store(
                initialState: AnnouncementFeature.State(
                    announcementId: 0,
                    announcementName: "Name"
                )
            ) {
                AnnouncementFeature()
            }
        )
    }
}
