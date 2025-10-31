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
            if #available(iOS 26, *), store.appSettings.floatingNavigation {
                if store.totalPages > 1 {
                    LiquidNavigation()
                }
            } else {
                LegacyNavigation()
            }
        }
    }
    
    // MARK: - Liquid Navigation
    
    @available(iOS 26, *)
    @ViewBuilder
    private func LiquidNavigation() -> some View {
        HStack(spacing: 0) {
            Button {
                store.send(.firstPageTapped)
            } label: {
                NavigationArrow(symbol: .chevronLeft2)
            }
            .buttonStyle(.plain)
            .disabled(store.currentPage == 1)
            .padding(.leading, 16)
            
            Spacer()
            
            Button {
                store.send(.previousPageTapped)
            } label: {
                NavigationArrow(symbol: .chevronLeft)
            }
            .buttonStyle(.plain)
            .disabled(store.currentPage == 1)
            
            Spacer()
            
            HStack(spacing: 6) {
                TextField(String(""), text: $store.page)
                    .font(.subheadline.monospacedDigit())
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
                            .font(.subheadline.monospacedDigit())
                            .fixedSize()
                            .opacity(store.focus == nil ? 1 : 0)
                            .contentTransition(.numericText())
                            .animation(.default, value: store.page)
                    }
                
                Text(verbatim: "/")
                    .font(.subheadline.monospacedDigit())
                
                Text(verbatim: "\(store.totalPages)")
                    .font(.subheadline.monospacedDigit())
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(Color(.Background.teritary))
                    .glassEffect(.identity)
            )
            .onTapGesture {
                store.send(.onViewTapped)
            }
            
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
            .padding(.trailing, 16)
        }
        .bind($store.focus, to: $focus)
        .if(!store.appSettings.experimentalFloatingNavigation) { content in
            content
                .padding(.vertical, 8)
                .contentShape(.rect)
                .frame(maxWidth: .infinity)
                .glassEffect(.regular.interactive())
        }
    }
    
    // MARK: - Legacy Navigation
    
    @ViewBuilder
    private func LegacyNavigation() -> some View {
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

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    @Previewable @State var store = Store(
        initialState: PageNavigationFeature.State(type: .forum)
    ) {
        PageNavigationFeature()
    }
    
    @Shared(.appSettings) var appSettings
    let _ = $appSettings.floatingNavigation.withLock { $0 = true }
    
    ZStack {
        LinearGradient(
            colors: [.red, .blue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        PageNavigation(store: store)
            .padding(.horizontal, 16)
            .onAppear {
                store.send(.update(count: 50000, offset: 0))
            }
    }
}
