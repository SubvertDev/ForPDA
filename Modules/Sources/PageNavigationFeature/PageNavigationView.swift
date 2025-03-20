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
    @FocusState var isFocused: Bool
    
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
            //            Button {
            //                print("tapped page nav")
            //            } label: {
            //                Text(String("\(store.currentPage) / \(store.totalPages)"))
            //                    .font(.subheadline)
            //                    .foregroundStyle(Color(.Labels.secondary))
            //                    .padding(.vertical, 6)
            //                    .padding(.horizontal, 12)
            //                    .background(
            //                        RoundedRectangle(cornerRadius: 8)
            //                            .foregroundStyle(Color(.Background.teritary))
            //                    )
            //                    .contentTransition(.numericText())
            //            }
            HStack {
                ZStack {
                    Text("\(store.currentPage)")
                        .font(.system(size: 17))
                        .background(GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    store.send(.updateWidth(geometry: geometry))
                                }
                                .onChange(of: store.pageText) { _ in
                                    store.send(.updateWidth(geometry: geometry))
                                }
                        })
                        .hidden()
                    
                    TextField("", text: $store.pageText)
                        .frame(width: store.textWidth, alignment: .leading)
                        .focused($isFocused)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .animation(.easeInOut(duration: 0.2), value: store.textWidth)
                        .onChange(of: store.pageText) { newValue in
                            let filtered = newValue.filter { $0.isNumber }
                            if let intValue = Int(filtered), intValue > store.totalPages {
                                store.send(.updatePageText(value: "\(store.totalPages)"))
                            }
                            else {
                                store.send(.updatePageText(value: filtered))
                            }
                        }
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                
                                Button("Готово") {
                                    isFocused = false
                                    store.send(.doneButtonTapped)
                                }
                            }
                        }
                }
                
                Text("/  \(store.totalPages)")
                    .font(.system(size: 17))
                    .onTapGesture {
                        isFocused = true
                    }
            }
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
