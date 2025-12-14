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
    @Binding private var minimized: Bool
    @Environment(\._tabViewBottomAccessoryPlacement) var placement
    
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
                
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 6) {
                        PageField()
                        
                        Text(verbatim: "/")
                            .font(.subheadline.monospacedDigit())
                        
                        Text(verbatim: "\(store.totalPages)")
                            .font(.subheadline.monospacedDigit())
                    }
                    
                    PageField()
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundStyle(Color(.Background.teritary))
                        .if(!store.appSettings.experimentalFloatingNavigation) { content in
                            content
                                .glassEffect(.identity)
                        }
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
    
    @ViewBuilder
    private func PageField() -> some View {
        TextField(String(""), text: $store.page)
            .font(.subheadline.monospacedDigit())
            .keyboardType(.numberPad)
            .focused($focus, equals: PageNavigationFeature.State.Field.page)
            .fixedSize()
            .onChange(of: store.page) { newValue in
                guard !store.page.isEmpty else { return }
                store.page = String(min(Int(store.page.filter(\.isNumber)) ?? 1, store.totalPages))
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
#Preview("Base navigation") {
    @Previewable @State var store = Store(
        initialState: PageNavigationFeature.State(type: .forum)
    ) {
        PageNavigationFeature()
    }
    @Previewable @State var minimized = false
    
    @Shared(.appSettings) var appSettings
    
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
        $appSettings.floatingNavigation.withLock { $0 = true }
        store.send(.update(count: 50000, offset: 0))
    }
}

@available(iOS 26.2, *)
#Preview("Experimental navigation") {
    @Previewable @State var store = Store(
        initialState: PageNavigationFeature.State(type: .forum)
    ) {
        PageNavigationFeature()
    }
    
    @Shared(.appSettings) var appSettings

    WithPerceptionTracking {
        TabView {
            Tab {
                ZStack {
                    LinearGradient(
                        colors: [.red, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    ScrollView(.vertical) {
                        ForEach(0..<100) { index in
                            Text(String(index))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .overlay {
                        VStack {
                            Button(String("Enable")) {
                                store.send(.update(count: 50000, offset: 50000-20))
                            }
                            Button(String("Disable")) {
                                store.send(.update(count: 0, offset: 0))
                            }
                        }
                        .background(.white)
                    }
                }
            } label: {
                Label(String("Test"), systemSymbol: .paperclip)
            }
            
            Tab {}; Tab {}; Tab {}
        }
        .tabViewBottomAccessory(isEnabled: store.totalPages > 1) {
            PageNavigation(store: store)
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .onAppear {
            $appSettings.floatingNavigation.withLock { $0 = true }
            $appSettings.experimentalFloatingNavigation.withLock { $0 = true }
            store.send(.update(count: 50000, offset: 50000-20))
        }
        .animation(.default, value: store.count)
    }
}
