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
    
    public init(store: StoreOf<ForumFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
//            List(store.sections, children: \.subtopics) { section in
//                WithPerceptionTracking {
//                    if section.typeId == 0 {
//                        Button {
//                            store.send(.topicTapped(id: section.id))
//                        } label: {
//                            Text(section.title)
//                                .foregroundStyle(Color(.label))
//                        }
//                    } else {
//                        Text(section.title)
//                    }
//                }
//            }
//            .navigationTitle(Text("Forum", bundle: .module))
//            .navigationBarTitleDisplayMode(.inline)
//            .task {
//                store.send(.onTask)
//            }
        }
    }
}

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
