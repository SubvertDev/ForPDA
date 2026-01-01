//
//  BBPanelType.swift
//  ForPDA
//
//  Created by Xialtal on 28.12.25.
//

import SwiftUI

public enum BBPanelType: Equatable {
    case qms
    case post(isCurator: Bool, canModerate: Bool)
    case profile
    case custom([BBPanelTag])
}

extension BBPanelType {
    var kit: [BBPanelTag] {
        switch self {
        case .qms:
            return [.smile, .b, .i, .u, .s, .quote, .code]
        case .post:
            return [
                .smile, .b, .i, .u, .s, .size, .color, .url, .listBullet, .listNumber, .quote,
                .spoiler, .spoilerWithTitle, .code, .left, .center, .right, .sub, .sup, .offtop, .hide
            ]
        case .profile:
            return [.b, .i, .u, .s, .color, .url, .left, .center, .right, .sub, .sup, .offtop]
        case .custom(let array):
            return array
        }
    }
}
