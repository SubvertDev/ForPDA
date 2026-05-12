//
//  TicketStatusHistoryView.swift
//  ForPDA
//
//  Created by Xialtal on 10.05.26.
//

import SwiftUI
import ComposableArchitecture
import Models
import SharedUI
import SFSafeSymbols

@ViewAction(for: TicketStatusHistoryFeature.self)
public struct TicketStatusHistoryView: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<TicketStatusHistoryFeature>
    @Environment(\.tintColor) private var tintColor
    
    // MARK: - Init
    
    public init(store: StoreOf<TicketStatusHistoryFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            List {
                ForEach(store.history) { status in
                    Status(status)
                }
            }
            .listStyle(.plain)
            ._toolbarTitleDisplayMode(.inline)
            .navigationTitle(Text("Status History", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        send(.closeButtonTapped)
                    } label: {
                        if isLiquidGlass {
                            Image(systemSymbol: .xmark)
                        } else {
                            Image(systemSymbol: .xmark)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(Color(.Labels.teritary))
                                .frame(width: 30, height: 30)
                                .background(
                                    Circle()
                                        .fill(Color(.Background.quaternary))
                                        .clipShape(Circle())
                                )
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                CloseButton()
            }
            .overlay {
                if store.isLoading {
                    PDALoader()
                        .frame(width: 24, height: 24)
                } else if store.history.isEmpty {
                    LoadingError()
                }
            }
            .background(Color(.Background.primary))
            .onAppear {
                send(.onAppear)
            }
        }
    }
    
    // MARK: - Status
    
    @ViewBuilder
    private func Status(_ status: TicketStatusHistory) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(status.status.title, bundle: .module)
                    .font(.subheadline)
             
                Spacer()
                
                if status.handlerId > 0 {
                    Button {
                        send(.handlerButtonTapped(status.handlerId))
                    } label: {
                        HandlerBadge(name: status.handlerName)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Text(verbatim: status.changedAt.formatted())
                .font(.caption)
                .foregroundStyle(Color(.Labels.quaternary))
        }
        .listRowBackground(Color.clear)
    }
    
    // MARK: - Handler Badge
    
    private func HandlerBadge(name: String) -> some View {
        HStack(spacing: 4) {
            Image(systemSymbol: .personCropCircle)
            
            Text(verbatim: name)
        }
        .font(.caption)
        .foregroundStyle(Color(.Labels.teritary))
        .padding(.vertical, 2)
        .padding(.horizontal, 6)
        .background(
            Color(.Background.teritary)
                .clipShape(RoundedRectangle(cornerRadius: isLiquidGlass ? 10 : 6))
        )
    }
    
    // MARK: - Close Button
    
    @ViewBuilder
    private func CloseButton() -> some View {
        Button {
            send(.closeButtonTapped)
        } label: {
            Text("Okay", bundle: .module)
                .frame(maxWidth: .infinity)
                .padding(8)
            
        }
        .buttonStyle(.borderedProminent)
        .tint(tintColor)
        .frame(height: 48)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(.Background.primary))
    }
    
    // MARK: - Loading Error
    
    private func LoadingError() -> some View {
        VStack(spacing: 0) {
            Image(systemSymbol: .clockArrowCirclepath)
                .font(.title)
                .foregroundStyle(tintColor)
                .frame(width: 48, height: 48)
                .padding(.bottom, 8)
            
            Text("Loading Error", bundle: .module)
                .font(.title3)
                .bold()
                .foregroundStyle(Color(.Labels.primary))
                .padding(.bottom, 6)
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        TicketStatusHistoryView(
            store: Store(
                initialState: TicketStatusHistoryFeature.State(
                    ticketId: 0
                )
            ) {
                TicketStatusHistoryFeature()
            }
        )
    }
}
