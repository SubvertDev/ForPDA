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

public struct PageNavigation: View {
    
    // MARK: - Properties
    
    public var store: StoreOf<PageNavigationFeature>
    
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
        HStack(spacing: 0) {
            Button {
                store.send(.firstPageTapped)
            } label: {
                NavigationArrow(symbol: .chevronLeft2)
            }
            .buttonStyle(.plain)
            .disabled(store.currentPage == 1)
            
            Spacer()
            
            Button {
                store.send(.previousPageTapped)
            } label: {
                NavigationArrow(symbol: .chevronLeft)
            }
            .buttonStyle(.plain)
            .disabled(store.currentPage == 1)
            
            Spacer()
            
            Text(String("\(store.currentPage) / \(store.totalPages)"))
                .font(.subheadline)
                .foregroundStyle(Color.Labels.secondary)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundStyle(Color.Background.teritary)
                )
            
            Spacer()
            
            Button {
                store.send(.nextPageTapped)
            } label: {
                NavigationArrow(symbol: .chevronRight)
            }
            .buttonStyle(.plain)
            .disabled(store.currentPage + 1 > store.totalPages)
            
            Spacer()
            
            Button {
                store.send(.lastPageTapped)
            } label: {
                NavigationArrow(symbol: .chevronRight2)
            }
            .buttonStyle(.plain)
            .disabled(store.currentPage + 1 > store.totalPages)
        }
        .listRowSeparator(.hidden)
        .animation(.default, value: store.currentPage)
        .frame(maxWidth: .infinity, maxHeight: 32)
    }
    
    // MARK: - Navigation Arrow
    
    @ViewBuilder
    private func NavigationArrow(symbol: SFSymbol) -> some View {
        Image(systemSymbol: symbol)
            .font(.body)
            .frame(width: 32, height: 32)
    }
}

// MARK: - Extensions

extension NoticeType {
    public var color: Color {
        switch self {
        case .curator:   return Color.Main.green
        case .moderator: return Color.Theme.primary
        case .admin:     return Color.Main.red
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
