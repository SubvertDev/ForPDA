//
//  PasteboardClient.swift
//
//
//  Created by Ilia Lubianoi on 18.05.2024.
//

import UIKit
import ComposableArchitecture

@DependencyClient
public struct PasteboardClient {
    public var copy: (_ url: URL) -> Void
}

public extension DependencyValues {
    var pasteboardClient: PasteboardClient {
        get { self[PasteboardClient.self] }
        set { self[PasteboardClient.self] = newValue }
    }
}

extension PasteboardClient: DependencyKey {
    public static let liveValue = Self(
        copy: { url in
            UIPasteboard.general.string = url.absoluteString
        }
    )
}

