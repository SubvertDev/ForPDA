//
//  ImageClient.swift
//
//
//  Created by Ilia Lubianoi on 18.05.2024.
//

import Foundation
import ComposableArchitecture
import Nuke

@DependencyClient
public struct ImageClient: Sendable {
    public var configure: @Sendable () -> Void
}

public extension DependencyValues {
    var imageClient: ImageClient {
        get { self[ImageClient.self] }
        set { self[ImageClient.self] = newValue }
    }
}

extension ImageClient: DependencyKey {
    public static let liveValue = Self(
        configure: {
            ImagePipeline.shared = ImagePipeline(configuration: .withDataCache)
        }
    )
}
