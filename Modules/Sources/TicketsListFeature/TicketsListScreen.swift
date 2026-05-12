//
//  TicketsListScreen.swift
//  ForPDA
//
//  Created by Xialtal on 8.05.26.
//

import SwiftUI
import ComposableArchitecture
import Models
import SharedUI
import PageNavigationFeature
import SFSafeSymbols
import TicketStatusHistoryFeature

@ViewAction(for: TicketsListFeature.self)
public struct TicketsListScreen: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<TicketsListFeature>
    @Environment(\.tintColor) private var tintColor
    
    @State private var navigationMinimized = false
    
    private var shouldShowInlineNavigation: Bool {
        let isAnyFloatingNavigationEnabled = store.appSettings.floatingNavigation || store.appSettings.experimentalFloatingNavigation
        return store.pageNavigation.shouldShow && (!isLiquidGlass || !isAnyFloatingNavigationEnabled)
    }
    
    private var shouldShowFloatingNavigation: Bool {
        return isLiquidGlass && store.appSettings.floatingNavigation && !store.appSettings.experimentalFloatingNavigation
    }
    
    // MARK: - Init
    
    public init(store: StoreOf<TicketsListFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                if !store.isLoading {
                    if !store.tickets.isEmpty {
                        List {
                            if shouldShowInlineNavigation {
                                Navigation()
                            }
                            
                            Content()
                            
                            if shouldShowInlineNavigation {
                                Navigation()
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        ._inScrollContentDetector(isEnabled: shouldShowFloatingNavigation, state: $navigationMinimized)
                    } else {
                        NothingFound()
                    }
                }
            }
            .overlay {
                if store.isLoading {
                    PDALoader()
                        .frame(width: 24, height: 24)
                }
            }
            .navigationTitle(Text(navigationTitleText(), bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.Background.primary))
            .toolbar {
                ToolbarItem {
                    OptionsMenu()
                }
            }
            .safeAreaInset(edge: .bottom) {
                if shouldShowFloatingNavigation {
                    PageNavigation(
                        store: store.scope(state: \.pageNavigation, action: \.pageNavigation),
                        minimized: $navigationMinimized
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
            .sheet(item: $store.scope(state: \.$destination, action: \.destination).statusHistory) { store in
                NavigationStack {
                    TicketStatusHistoryView(store: store)
                }
            }
            .refreshable {
                await send(.onRefresh).finish()
            }
            .onFirstAppear {
                send(.onFirstAppear)
            }
        }
    }
    
    // MARK: - Options Menu
    
    @ViewBuilder
    private func OptionsMenu() -> some View {
        Menu {
            Section {
                Toggle(
                    LocalizedStringResource("Only My", bundle: .module),
                    isOn: Binding(store.$appSettings.tickets.isShowOnlyMine)
                )
                
                if case .list = store.type {
                    Toggle(
                        LocalizedStringResource("Sort by Forums", bundle: .module),
                        isOn: Binding(store.$appSettings.tickets.isSortByForums)
                    )
                }
            } header: {
                Text("Sort", bundle: .module)
            }
           
            ContextButton(text: LocalizedStringResource("Copy Link", bundle: .module), symbol: .docOnDoc) {
                send(.contextMenu(.copyLink))
            }
        } label: {
            Image(systemSymbol: .ellipsisCircle)
        }
    }
    
    // MARK: - Ticket Context Menu
    
    @ViewBuilder
    private func TicketContextMenu(id: Int, _ ticket: TicketInfo) -> some View {
        Menu {
            Section {
                Menu {
                    TicketStatusPicker(id: id)
                } label: {
                    HStack {
                        Text("Change Status", bundle: .module)
                        Image(systemSymbol: .checklist)
                    }
                }
                
                ContextButton(text: LocalizedStringResource("Status History", bundle: .module), symbol: .clockArrowCirclepath) {
                    send(.contextTicketMenu(.statusHistory, id))
                }
            }
            
            Section {
                ContextButton(text: LocalizedStringResource("Go to Author", bundle: .module), symbol: .personCropCircle) {
                    send(.contextTicketMenu(.openAuthor(ticket.authorId), id))
                }
            }
            
            Section {
                ContextButton(text: LocalizedStringResource("Copy Link", bundle: .module), symbol: .docOnDoc) {
                    send(.contextTicketMenu(.copyLink, id))
                }
            }
        } label: {
            Image(systemSymbol: .ellipsis)
                .font(.body)
                .foregroundStyle(Color(.Labels.teritary))
                .padding(.horizontal, 8) // Padding for tap area
                .padding(.vertical, 16)
        }
        .onTapGesture {} // DO NOT DELETE, FIX FOR IOS 17
        .frame(width: 8, height: 22)
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private func Content() -> some View {
        ForEach(store.tickets) { ticket in
            Button {
                send(.ticketButtonTapped(ticket.id))
            } label: {
                TicketRow(ticket)
            }
            .buttonStyle(.plain)
            .listRowBackground(Color.clear)
        }
    }
    
    // MARK: - Ticket Row
    
    @ViewBuilder
    private func TicketRow(_ ticket: TicketsList.TicketSimplified) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Menu {
                TicketStatusPicker(id: ticket.id)
            } label: {
                TicketStatusBadge(info: ticket.info)
            }
            
            Text(verbatim: ticket.info.title)
                .font(.subheadline)
                .foregroundStyle(Color(.Labels.primary))
            
            HStack(spacing: 6) {
                Image(systemSymbol: .textBubble)
                
                Text(verbatim: ticket.info.subjectRootName)
            }
            .font(.caption)
            .foregroundStyle(Color(.Labels.teritary))
            
            HStack {
                HStack(spacing: 0) {
                    let date = if ticket.info.status == .processed {
                        ticket.info.processedAt ?? Date.unknown
                    } else {
                        ticket.info.createdAt
                    }
                    Text(verbatim: "\(date.formatted()) · ")
                    
                    HStack(spacing: 4) {
                        Image(systemSymbol: .personCropCircle)
                        
                        Text(verbatim: ticket.info.authorName)
                    }
                }
                
                Spacer()
                
                TicketContextMenu(id: ticket.id, ticket.info)
            }
            .font(.caption)
            .foregroundStyle(Color(.Labels.quaternary))
        }
    }
    
    // MARK: - Ticket Status Badge
    
    @ViewBuilder
    private func TicketStatusBadge(info: TicketInfo) -> some View {
        let text: LocalizedStringKey = switch info.status {
        case .notProcessed: "New"
        case .processing:   "Processing · "
        case .processed:    "Processed · "
        }
        HStack(spacing: 0) {
            Text(text, bundle: .module)
            
            if info.handlerId > 0 {
                HStack(spacing: 4) {
                    Image(systemSymbol: .personCropCircle)
                    
                    Text(verbatim: info.handlerName)
                }
            }
        }
        .font(.caption)
        .foregroundStyle(info.status.textColor)
        .padding(.vertical, 2)
        .padding(.horizontal, 6)
        .background(
            info.status.maskColor
                .clipShape(RoundedRectangle(cornerRadius: isLiquidGlass ? 10 : 6))
        )
    }
    
    // MARK: - Ticket Status Picker
    
    private func TicketStatusPicker(id: Int) -> some View {
        WithPerceptionTracking {
            let status = store.tickets[id].info.status
            Picker(String(), selection: Binding(
                get: { status },
                set: { newValue in
                    send(.contextTicketMenu(.changeStatus(newValue), id))
                }
            )) {
                ForEach(TicketStatus.allCases) { status in
                    Text(status.title, bundle: .module)
                        .tag(status)
                }
            }
        }
    }
    
    // MARK: - Navigation
    
    @ViewBuilder
    private func Navigation() -> some View {
        PageNavigation(store: store.scope(state: \.pageNavigation, action: \.pageNavigation))
            .listRowBackground(Color(.Background.primary))
    }
    
    // MARK: - Nothing Found
    
    private func NothingFound() -> some View {
        VStack(spacing: 0) {
            Image(systemSymbol: .exclamationmarkBubble)
                .font(.title)
                .foregroundStyle(tintColor)
                .frame(width: 48, height: 48)
                .padding(.bottom, 8)
            
            Text("No Tickets", bundle: .module)
                .font(.title3)
                .bold()
                .foregroundStyle(Color(.Labels.primary))
                .padding(.bottom, 6)
            
            Text("When requests come in, they will appear here", bundle: .module)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(.Labels.teritary))
                .frame(maxWidth: UIScreen.main.bounds.width * 0.7)
                .padding(.horizontal, 55)
        }
    }
    
    // MARK: - Helpers
    
    private func navigationTitleText() -> LocalizedStringKey {
        return switch store.type {
        case .list:  "Tickets"
        case .topic: "Topic Tickets"
        }
    }
}

// MARK: - Extensions

extension TicketStatus {
    var maskColor: Color {
        switch self {
        case .notProcessed: Color(.Main.redAlpha)
        case .processing:   Color(.Main.yellowAlpha)
        case .processed:    Color(.Background.teritary)
        }
    }
    
    var textColor: Color {
        switch self {
        case .notProcessed: Color(.Main.red)
        case .processing:   Color(.Main.yellow)
        case .processed:    Color(.Labels.teritary)
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        TicketsListScreen(
            store: Store(
                initialState: TicketsListFeature.State(
                    type: .list
                )
            ) {
                TicketsListFeature()
            }
        )
    }
    .tint(Color(.Theme.primary))
}
