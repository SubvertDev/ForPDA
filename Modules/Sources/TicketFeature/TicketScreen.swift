//
//  TicketScreen.swift
//  ForPDA
//
//  Created by Xialtal on 5.05.26.
//

import SwiftUI
import ComposableArchitecture
import Models
import SharedUI
import SFSafeSymbols
import RichTextKit
import TicketStatusHistoryFeature
import TopicBuilder

@ViewAction(for: TicketFeature.self)
public struct TicketScreen: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<TicketFeature>
    @Environment(\.tintColor) private var tintColor
    
    // MARK: - Init
    
    public init(store: StoreOf<TicketFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                ScrollView {
                    if let ticket = store.ticket {
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(spacing: 8) {
                                Divider()
                                
                                TicketHeader(ticket.info)
                                
                                Divider()
                            }
                            
                            if let content = ticket.comments.first {
                                AttributedContent(content)
                            }
                            
                            Section {
                                VStack(alignment: .leading, spacing: 8) {
                                    if ticket.comments.count > 1 {
                                        Divider()
                                        
                                        ForEach(ticket.comments.suffix(from: 1)) { comment in
                                            Comment(comment)
                                            
                                            Divider()
                                        }
                                    } else {
                                        NoComments()
                                            .padding(.top, 84)
                                    }
                                }
                            } header: {
                                Text("Comments", bundle: .module)
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color(.Labels.primary))
                                    .padding(.top, 28)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .navigationTitle(Text(store.ticket != nil ? "Ticket \(String(store.id))" : "Loading...", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .alert($store.scope(state: \.$destination, action: \.destination).alert)
            .sheet(item: $store.scope(state: \.$destination, action: \.destination).statusHistory) { store in
                NavigationStack {
                    TicketStatusHistoryView(store: store)
                }
            }
            .alert(
                item: $store.destination.editComment,
                title: { _ in Text("Change ticket comment", bundle: .module) }
            ) { commentId in
                AlertInput({
                    send(.commentButtonTapped(commentId, isAdd: false))
                })
            }
            .alert(
                item: $store.destination.addComment,
                title: { _ in Text("Add ticket comment", bundle: .module) }
            ) {
                AlertInput({
                    send(.commentButtonTapped(0, isAdd: true))
                })
            }
            ._safeAreaBar(edge: .bottom) {
                if store.ticket != nil {
                    ActionButtons()
                }
            }
            .toolbar {
                ToolbarItem {
                    OptionsMenu()
                }
            }
            .refreshable {
                await send(.onRefresh).finish()
            }
            .onAppear {
                send(.onAppear)
            }
        }
    }
    
    // MARK: - Options Menu
    
    @ViewBuilder
    private func OptionsMenu() -> some View {
        Menu {
            Section {
                ContextButton(text: LocalizedStringResource("Status History", bundle: .module), symbol: .clockArrowCirclepath) {
                    send(.contextMenu(.statusHistory))
                }
            }
            
            Section {
                ContextButton(text: LocalizedStringResource("Go to Author", bundle: .module), symbol: .personCropCircle) {
                    send(.contextMenu(.openAuthor))
                }
            }
           
            ContextButton(text: LocalizedStringResource("Copy Link", bundle: .module), symbol: .docOnDoc) {
                send(.contextMenu(.copyLink))
            }
        } label: {
            Image(systemSymbol: .ellipsisCircle)
        }
    }
    
    // MARK: - Action Buttons
    
    @ViewBuilder
    private func ActionButtons() -> some View {
        HStack {
            WithPerceptionTracking {
                Menu {
                    let status = store.ticket!.info.status
                    Picker(String(), selection: Binding(
                        get: { status },
                        set: { newValue in
                            send(.changeStatusButtonTapped(newValue))
                        }
                    )) {
                        ForEach(TicketStatus.allCases) { status in
                            Text(status.title)
                                .tag(status)
                        }
                    }
                } label: {
                    Text("Change status", bundle: .module)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                }
                .tint(tintColor)
                .buttonStyle(.bordered)
                .frame(height: 48)
            }
            
            Button {
                send(.showAddCommentAlertButtonTapped)
            } label: {
                Text("Comment", bundle: .module)
                    .frame(maxWidth: .infinity)
                    .padding(8)
            }
            .buttonStyle(.borderedProminent)
            .frame(height: 48)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Comment
    
    @ViewBuilder
    private func Comment(_ comment: UITicket.HybridComment) -> some View {
        HStack(alignment: .top) {
            Image(systemSymbol: .bubbleLeft)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        send(.commentAuthorButtonTapped(comment.comment.authorId))
                    } label: {
                        Text(verbatim: comment.comment.authorName)
                            .foregroundStyle(tintColor)
                            .underline()
                    }
                    .buttonStyle(.plain)
                    
                    AttributedContent(comment)
                }
                .font(.subheadline)
                
                HStack {
                    Text(verbatim: comment.comment.createdAt.formatted())
                        .font(.caption)
                        .foregroundStyle(Color(.Labels.quaternary))
                    
                    Spacer()
                    
                    WithPerceptionTracking {
                        if let session = store.userSession, session.userId == comment.comment.authorId {
                            CommentContextMenu(id: comment.id)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Comment Context Menu
    
    @ViewBuilder
    private func CommentContextMenu(id: Int) -> some View {
        Menu {
            ContextButton(text: LocalizedStringResource("Edit", bundle: .module), symbol: .squareAndPencil) {
                send(.contextCommentMenu(.edit(id)))
            }
            
            Button(role: .destructive) {
                send(.contextCommentMenu(.delete(id)))
            } label: {
                HStack {
                    Text("Delete", bundle: .module)
                    Image(systemSymbol: .trash)
                }
            }
            .tint(.red)
        } label: {
            Image(systemSymbol: .ellipsis)
                .font(.body)
                .foregroundStyle(Color(.Labels.teritary))
                .padding(.horizontal, 8) // Padding for tap area
                .padding(.vertical, 16)
        }
        .onTapGesture {} // DO NOT DELETE, FIX FOR IOS 17
        .frame(width: 18, height: 22)
    }
    
    // MARK: - Attributed Content
    
    @ViewBuilder
    private func AttributedContent(_ comment: UITicket.HybridComment) -> some View {
        if !comment.uiContent.isEmpty {
            ForEach(comment.uiContent, id: \.self) { type in
                WithPerceptionTracking {
                    TopicView(type: type, attachments: []) { url in
                        send(.urlTapped(url))
                    }
                }
            }
        } else {
            Text(verbatim: comment.comment.content)
                .font(.subheadline)
        }
    }
    
    // MARK: - Ticket Header
    
    @ViewBuilder
    private func TicketHeader(_ ticket: TicketInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TicketStatusBadge(info: ticket)
            
            Text(verbatim: ticket.title)
                .font(.subheadline)
                .foregroundStyle(Color(.Labels.primary))
            
            HStack(spacing: 6) {
                Image(systemSymbol: .textBubble)
                
                Text(verbatim: ticket.subjectRootName)
            }
            .font(.caption)
            .foregroundStyle(Color(.Labels.teritary))
            
            HStack {
                HStack(spacing: 0) {
                    let date = if ticket.status == .processed {
                        ticket.processedAt ?? Date.unknown
                    } else {
                        ticket.createdAt
                    }
                    Text(verbatim: "\(date.formatted()) · ")
                    
                    HStack(spacing: 4) {
                        Image(systemSymbol: .personCropCircle)
                        
                        Text(verbatim: ticket.authorName)
                    }
                }
                
                Spacer()
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
    
    // MARK: - Alert Input
    
    @ViewBuilder
    private func AlertInput(_ action: @escaping () -> Void) -> some View {
        WithPerceptionTracking {
            TextField(String(localized: "Input comment...", bundle: .module), text: $store.alertInput)
            
            Button(LocalizedStringResource("Cancel", bundle: .module)) { }
            
            Button(LocalizedStringResource("Send", bundle: .module)) {
                action()
            }
            .disabled(store.alertInput.isEmpty)
        }
    }
    
    // MARK: - No Comments
    
    private func NoComments() -> some View {
        VStack(spacing: 0) {
            Image(systemSymbol: .bubbleLeft)
                .font(.title)
                .foregroundStyle(tintColor)
                .frame(width: 48, height: 48)
                .padding(.bottom, 8)
            
            Text("No Comments", bundle: .module)
                .font(.title3)
                .bold()
                .foregroundStyle(Color(.Labels.primary))
                .padding(.bottom, 6)
            
            Text("Add the first one for other moderators", bundle: .module)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(.Labels.teritary))
                .frame(maxWidth: UIScreen.main.bounds.width * 0.7)
                .padding(.horizontal, 55)
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

#Preview("Ticket") {
    NavigationStack {
        TicketScreen(
            store: Store(
                initialState: TicketFeature.State(id: 0)
            ) {
                TicketFeature()
            }
        )
    }
}
