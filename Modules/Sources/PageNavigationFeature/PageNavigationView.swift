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

extension Binding where Value == Bool {
    static func orFalse(_ binding: Binding<Bool>?) -> Binding<Bool> {
        binding ?? .constant(false)
    }
}

public struct PageNavigation: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<PageNavigationFeature>
    @FocusState private var focus: PageNavigationFeature.State.Field?
    @Binding private var minimized: Bool
    
    // MARK: - Init
    
    public init(
        store: StoreOf<PageNavigationFeature>,
        minimized: Binding<Bool> = .constant(false)
    ) {
        self.store = store
        self._minimized = minimized
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            if #available(iOS 26, *), store.appSettings.floatingNavigation {
                if store.shouldShow {
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
            if !minimized {
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
            }
            
            Button {
                if minimized {
                    withAnimation {
                        minimized = false
                    }
                } else {
                    store.send(.lastPageTapped)
                }
            } label: {
                NavigationArrow(symbol: .chevronRight2)
            }
            .buttonStyle(.plain)
            .disabled(
                minimized
                ? false
                : store.currentPage + 1 > store.totalPages
            )
            .padding(.trailing, minimized ? 0 : 16)
        }
        .bind($store.focus, to: $focus)
        .if(!store.appSettings.experimentalFloatingNavigation) { content in
            content
                .padding(.vertical, 8)
                .padding(.horizontal, minimized ? 8 : 0)
                .contentShape(.rect)
                .clipped()
                .glassEffect(.regular.interactive())
                .frame(maxWidth: .infinity, alignment: .trailing)
                .animation(.default, value: minimized)
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
    @Previewable @State var minimized = false
    
    @Shared(.appSettings) var appSettings
    let _ = $appSettings.floatingNavigation.withLock { $0 = true }
    
    ZStack {
        LinearGradient(
            colors: [.red, .blue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack {
            Spacer()
            
            Button(String("Minimized: \(minimized)")) {
                minimized.toggle()
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
            
            PageNavigation(store: store, minimized: $minimized)
                .padding(.horizontal, 16)
        }
    }
    .onAppear {
        store.send(.update(count: 50000, offset: 0))
    }
}
