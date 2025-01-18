//
//  SortView.swift
//  ForPDA
//
//  Created by Xialtal on 1.01.25.
//

import SwiftUI
import ComposableArchitecture
import SkeletonUI
import Models
import SharedUI

struct SortView: View {
    
    @Perception.Bindable var store: StoreOf<SortFeature>
    @Environment(\.tintColor) private var tintColor
    @State private var sortSelection: FavoriteSortType?
    @State private var sortSelections: Set<FavoriteSortType> = .init()
    
    init(store: StoreOf<SortFeature>) {
        self.store = store
    }
    
    var body: some View {
        NavigationStack {
            WithPerceptionTracking {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Sort", bundle: .module)
                            .font(.system(size: 20, weight: .semibold))
                        
                        Spacer()
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 4)
                    
                    HStack {
                        Picker("Sort", selection: $store.sortType) {
                            // FIXME: Translatable titles
                            Label(SortType.byDate.title, systemSymbol: .calendar).tag(SortType.byDate)
                            Label(SortType.byName.title, systemSymbol: .person).tag(SortType.byName)
                        }
                        .frame(maxWidth: .infinity, minHeight: 60)
                        
                    }
                    .listRowBackground(Color.Background.teritary)
                                    
                    Row("In reverse order", value: $store.isReverseOrder)
                    
                    Row("Unread first", value: $store.isUnreadFirst)
                    
                    HStack {
                        Button {
                            store.send(.cancelButtonTapped)
                        } label: {
                            Text("Cancel", bundle: .module)
                                .frame(maxWidth: .infinity)
                                .padding(8)
                        }
                        .buttonStyle(.bordered)
                        .frame(maxHeight: .infinity)
                        
                        Button {
                            store.send(.saveButtonTapped)
                        } label: {
                            Text("Apply", bundle: .module)
                                .frame(maxWidth: .infinity)
                                .padding(8)
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxHeight: .infinity)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .background(Color.Background.primary)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    @ViewBuilder
    private func Row(_ title: LocalizedStringKey, value: Binding<Bool>) -> some View {
        HStack(spacing: 0) {
            Text(title, bundle: .module)
                .foregroundStyle(Color.Labels.teritary)
                .font(.system(size: 15, weight: .semibold))
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 8)
            
            Toggle(String(""), isOn: value)
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        SortView(
            store: Store(
                initialState: SortFeature.State()
            ) {
                SortFeature()
            }
        )
    }
}
