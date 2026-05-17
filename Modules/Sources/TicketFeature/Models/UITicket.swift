//
//  UITicket.swift
//  ForPDA
//
//  Created by Xialtal on 16.05.26.
//

import Models
import SharedUI

struct UITicket: Sendable, Equatable {
    public var info: TicketInfo
    public let comments: [HybridComment]
    
    struct HybridComment: Sendable, Equatable, Identifiable {
        public let comment: Ticket.Comment
        public let uiContent: [UITopicType]
        
        public var id: Int {
            return comment.id
        }
        
        public init(
            comment: Ticket.Comment,
            uiContent: [UITopicType]
        ) {
            self.comment = comment
            self.uiContent = uiContent
        }
    }
    
    public init(info: TicketInfo, comments: [HybridComment]) {
        self.info = info
        self.comments = comments
    }
}
