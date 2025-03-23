//
//  PageNavigation.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 11.11.2024.
//

import SwiftUI
import ComposableArchitecture
import SFSafeSymbols
import Models
import SharedUI
import Perception

public struct PageNavigation: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<PageNavigationFeature>
    @FocusState private var focus: PageNavigationFeature.State.Field?
    
    // MARK: - Init
    
    public init(store: StoreOf<PageNavigationFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            PageNavigation()
        }
    }
    
    // MARK: - Page Navigation
    
    @ViewBuilder
    private func PageNavigation() -> some View {
        HStack(spacing: 32) {
            Button {
                store.send(.firstPageTapped)
            } label: {
                NavigationArrow(symbol: .chevronLeft2)
            }
            .buttonStyle(.plain)
            .disabled(store.currentPage == 1)
            
            Button {
                store.send(.previousPageTapped)
            } label: {
                NavigationArrow(symbol: .chevronLeft)
            }
            .buttonStyle(.plain)
            .disabled(store.currentPage == 1)
            
            Spacer()
            
            Button {
                store.send(.nextPageTapped)
            } label: {
                NavigationArrow(symbol: .chevronRight)
            }
            .buttonStyle(.plain)
            .disabled(store.currentPage + 1 > store.totalPages)
            
            Button {
                store.send(.lastPageTapped)
            } label: {
                NavigationArrow(symbol: .chevronRight2)
            }
            .buttonStyle(.plain)
            .disabled(store.currentPage + 1 > store.totalPages)
        }
        .overlay {
            HStack(spacing: 8) {
                TextField(String(""), text: $store.page)
                    .font(.subheadline)
                    .keyboardType(.numberPad)
                    .focused($focus, equals: PageNavigationFeature.State.Field.page)
                    .fixedSize()
                    .onChange(of: store.page) { newValue in
                        guard !store.page.isEmpty else { return }
                        store.page = String(min(Int(store.page.filter(\.isNumber))!, store.totalPages))
                    }
                    .toolbar {
                        if focus == .page {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                
                                Button {
                                    store.send(.doneButtonTapped)
                                } label: {
                                    Text("Done", bundle: .module)
                                }
                            }
                        }
                    }
                    .opacity(store.focus == nil ? 0 : 1)
                    .overlay {
                        Text(store.page)
                            .font(.subheadline)
                            .fixedSize()
                            .opacity(store.focus == nil ? 1 : 0)
                            .contentTransition(.numericText())
                            .animation(.default, value: store.page)
                    }
                
                Text(verbatim: "/")
                    .font(.subheadline)
                
                Text(verbatim: "\(store.totalPages)")
                    .font(.subheadline)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(Color(.Background.teritary))
            )
            .onTapGesture {
                store.send(.onViewTapped)
            }
        }
        .bind($store.focus, to: $focus)
        .listRowSeparator(.hidden)
    }
    
    // MARK: - Navigation Arrow
    
    @ViewBuilder
    private func NavigationArrow(symbol: SFSymbol) -> some View {
        Image(systemSymbol: symbol)
            .font(.body)
            .frame(width: 32, height: 32)
    }
}

// MARK: - Model Extensions

extension NoticeType {
    public var color: Color {
        switch self {
        case .curator:   return Color(.Main.green)
        case .moderator: return Color(.Theme.primary)
        case .admin:     return Color(.Main.red)
        }
    }
}

// MARK: - Previews

#Preview {
    PageNavigation(
        store: Store(
            initialState: PageNavigationFeature.State(type: .forum)
        ) {
            PageNavigationFeature()
        }
    )
}
