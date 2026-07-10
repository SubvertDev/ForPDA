//
//  ReputationModifyActionType+Extension.swift
//  ForPDA
//
//  Created by Xialtal on 16.05.26.
//

import PDAPI
import Models

extension ReputationModifyActionType {
    nonisolated var transferType: MemberReputationRequest.ActionType {
        switch self {
        case .delete:  .delete
        case .restore: .restore
        }
    }
}
