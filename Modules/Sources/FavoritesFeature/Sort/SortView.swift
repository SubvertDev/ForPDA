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
        WithPerceptionTracking {
            VStack(alignment: .leading, spacing: 0) {
                Text("Sort", bundle: .module)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 16)
                    .padding(.bottom, 22)
                
                HStack {
                    Menu {
                        Button {
                            store.send(.selectSortType(.byDate))
                        } label: {
                            Text(SortType.byDate.title)
                            Image(systemSymbol: .calendar)
                        }
                        
                        Button {
                            store.send(.selectSortType(.byName))
                        } label: {
                            Text(SortType.byName.title)
                            Image(systemSymbol: .person)
                        }
                    } label: {
                        HStack {
                            Text(store.sortType.title)
                                .foregroundStyle(.black)
                                .cornerRadius(10)
                                .padding(.leading, 16)
                            
                            Spacer()
                            
                            Image(systemSymbol: .chevronUpChevronDown)
                                .foregroundStyle(.black)
                                .padding(.trailing, 11)
                        }
                        .frame(minHeight: 60)
                        .background(Color(.Background.teritary))
                        .cornerRadius(10)
                    }
                }
                .listRowBackground(Color(.Background.teritary))
                .padding(.bottom, 28)
                
                Row("In reverse order", value: $store.isReverseOrder)
                    .padding(.bottom, 24)
                
                Row("Unread first", value: $store.isUnreadFirst)
                    .padding(.bottom, 64)
                
                HStack {
                    Button {
                        store.send(.cancelButtonTapped)
                    } label: {
                        Text("Cancel", bundle: .module)
                            .frame(maxWidth: .infinity)
                            .padding(8)
                    }
                    .buttonStyle(.bordered)
                    .frame(height: 48)

                    Button {
                        store.send(.saveButtonTapped)
                    } label: {
                        Text("Apply", bundle: .module)
                            .frame(maxWidth: .infinity)
                            .padding(8)
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(height: 48)
                }
                .padding(.vertical, 8)
            }
            .padding(.horizontal, 16)
            .background(Color(.Background.primary))
        }
    }
    
    @ViewBuilder
    private func Row(_ title: LocalizedStringKey, value: Binding<Bool>) -> some View {
        HStack(spacing: 0) {
            Text(title, bundle: .module)
                .foregroundStyle(Color(.Labels.teritary))
                .font(.subheadline)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Toggle(String(""), isOn: value)
                .labelsHidden()
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
