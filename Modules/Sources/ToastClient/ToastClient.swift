//
//  ToastClient.swift
//  AppFeature
//
//  Created by Ilia Lubianoi on 31.03.2025.
//

import SwiftUI
import ComposableArchitecture
import HapticClient
import Models

@DependencyClient
public struct ToastClient: Sendable {
    public var showToast: @Sendable (ToastMessage) async -> Void
    public var queue: @Sendable () -> AsyncStream<ToastMessage> = { .finished }
}

extension ToastClient: DependencyKey {
    public static var liveValue: ToastClient {
        @Dependency(\.hapticClient) var haptic
        
        let (stream, continuation) = AsyncStream.makeStream(of: ToastMessage.self)

        return ToastClient(
            showToast: { toast in
                if let hapticType = toast.haptic {
                    await haptic.play(hapticType)
                }
                continuation.yield(toast)
            },
            
            queue: { stream }
        )
    }
}

extension DependencyValues {
    public var toastClient: ToastClient {
        get { self[ToastClient.self] }
        set { self[ToastClient.self] = newValue }
    }
}
