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
import BBBuilder
import RichTextKit

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
            .navigationTitle(Text(store.ticket != nil ? "Ticket \(store.id)" : "Loading...", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.Background.primary))
            .toolbar {
                
            }
            .onAppear {
                send(.onAppear)
            }
        }
    }
    
    // MARK: - Comment
    
    @ViewBuilder
    private func Comment(_ comment: Ticket.Comment) -> some View {
        HStack(alignment: .top) {
            Image(systemSymbol: .bubbleLeft)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        send(.commentAuthorButtonTapped(comment.authorId))
                    } label: {
                        Text(verbatim: comment.authorName)
                            .foregroundStyle(tintColor)
                            .underline()
                    }
                    .buttonStyle(.plain)
                    
                    AttributedContent(comment)
                }
                .font(.subheadline)
                
                HStack {
                    Text(verbatim: comment.createdAt.formatted())
                        .font(.caption)
                        .foregroundStyle(Color(.Labels.quaternary))
                    
                    Spacer()
                    
                    // TODO: ContextMenu
                }
            }
        }
    }
    
    // MARK: - Attributed Content
    
    @ViewBuilder
    private func AttributedContent(_ comment: Ticket.Comment) -> some View {
        if let content = comment.contentAttributed {
            RichText(text: content, isSelectable: false, onUrlTap: { url in
                send(.urlTapped(url))
            })
        } else {
            Text(verbatim: comment.content)
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

extension Ticket.Comment {
    var contentAttributed: NSAttributedString? {
        guard !content.isEmpty else { return nil }
        return BBRenderer(baseAttributes: [.font: UIFont.preferredFont(forTextStyle: .subheadline)])
            .render(text: content)
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
