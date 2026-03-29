//
//  TopicEditView.swift
//  ForPDA
//
//  Created by Xialtal on 29.03.26.
//

import SwiftUI
import ComposableArchitecture
import SharedUI
import Models

public struct TopicEditView: View {
    
    @Perception.Bindable public var store: StoreOf<TopicEditFeature>
    @Environment(\.tintColor) private var tintColor
    
    public init(store: StoreOf<TopicEditFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
        }
    }
}

#Preview {
    
}
