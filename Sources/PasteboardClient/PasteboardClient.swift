//
//  PasteboardClient.swift
//
//
//  Created by Ilia Lubianoi on 18.05.2024.
//

import UIKit
import ComposableArchitecture

@DependencyClient
public struct PasteboardClient: Sendable {
    public var copy: @Sendable (_ string: String) -> Void
}

public extension DependencyValues {
    var pasteboardClient: PasteboardClient {
        get { self[PasteboardClient.self] }
        set { self[PasteboardClient.self] = newValue }
    }
}

extension PasteboardClient: DependencyKey {
    public static let liveValue = Self(
        copy: { string in
            UIPasteboard.general.string = string
        }
    )
}
