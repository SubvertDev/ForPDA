//
//  PageNavigation.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 11.11.2024.
//

import SwiftUI
import ComposableArchitecture
import SFSafeSymbols

public struct PageNavigation: View {
    public var store: StoreOf<PageNavigationFeature>
    
    public init(store: StoreOf<PageNavigationFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            PageNavigation()
        }
    }
    
    @ViewBuilder
    private func PageNavigation() -> some View {
        HStack(spacing: 16) {
            Button {
                store.send(.firstPageTapped)
            } label: {
                NavigationArrow(symbol: .arrowLeftToLine)
            }
            .buttonStyle(.plain)
            .disabled(store.currentPage == 1)
            
            Button {
                store.send(.previousPageTapped)
            } label: {
                NavigationArrow(symbol: .arrowLeft)
            }
            .buttonStyle(.plain)
            .disabled(store.currentPage == 1)
            
            Text(String("\(store.currentPage)/\(store.totalPages)"))
            
            Button {
                store.send(.nextPageTapped)
            } label: {
                NavigationArrow(symbol: .arrowRight)
            }
            .buttonStyle(.plain)
            .disabled(store.currentPage + 1 > store.totalPages)
            
            Button {
                store.send(.lastPageTapped)
            } label: {
                NavigationArrow(symbol: .arrowRightToLine)
            }
            .buttonStyle(.plain)
            .disabled(store.currentPage + 1 > store.totalPages)
        }
        .frame(maxWidth: .infinity, maxHeight: 32)
        .listRowSeparator(.hidden)
    }
    
    @ViewBuilder
    private func NavigationArrow(symbol: SFSymbol) -> some View {
        Image(systemSymbol: symbol)
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
    }
}

#Preview {
    PageNavigation(
        store: Store(
            initialState: PageNavigationFeature.State(type: .forum)
        ) {
            PageNavigationFeature()
        }
    )
}
