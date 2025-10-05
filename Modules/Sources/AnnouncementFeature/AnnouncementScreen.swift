//
//  AnnouncementScreen.swift
//  ForPDA
//
//  Created by Xialtal on 24.11.24.
//

import SwiftUI
import ComposableArchitecture
import PageNavigationFeature
import TopicBuilder
import SFSafeSymbols
import SharedUI
import Models

@ViewAction(for: AnnouncementFeature.self)
public struct AnnouncementScreen: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<AnnouncementFeature>
    @Environment(\.tintColor) private var tintColor
    
    // MARK: - Init
    
    public init(store: StoreOf<AnnouncementFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                if let announcement = store.announcement {
                    ScrollView {
                        AnnouncementBody(announcement)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .overlay {
                if store.announcement == nil {
                    PDALoader()
                        .frame(width: 24, height: 24)
                }
            }
            .navigationTitle(Text(store.name ?? "Загружаем..."))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // TODO: Announcement Info?
            }
            .onAppear {
                send(.onAppear)
            }
        }
    }
    
    // MARK: - Announcement Body
    
    @ViewBuilder
    private func AnnouncementBody(_ announcement: Announcement) -> some View {
        VStack(spacing: 0) {
            ForEach(store.types, id: \.self) { main in
                ForEach(main, id: \.self) { type in
                    TopicView(type: type, attachments: []) { url in
                        send(.urlTapped(url))
                    } // TODO: attachments
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
                    id: 0,
                    name: "Name"
                )
            ) {
                AnnouncementFeature()
            }
        )
    }
}
