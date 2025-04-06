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
    public var show: @Sendable (ToastInfo) async -> Void
    public var showToast: @Sendable (ToastMessage) async -> Void
    public var queue: @Sendable () -> AsyncStream<ToastMessage> = { .finished }
}

extension ToastClient: DependencyKey {
    public static var liveValue: ToastClient {
        @Dependency(\.hapticClient) var haptic
        let (stream, continuation) = AsyncStream.makeStream(of: ToastMessage.self)

        return ToastClient(
            show: { info in
                print("(DEPRECATED) SHOWING TOAST: \(info)")
            },
            
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

public enum ToastMessage: Equatable, Sendable {
    case custom(String)
    case postNotFound
    case whoopsSomethingWentWrong
    
    public var description: LocalizedStringKey {
        switch self {
        case .custom(let text):
            return LocalizedStringKey(text)
        case .postNotFound:
            return "Post not found"
        case .whoopsSomethingWentWrong:
            return "Whoops, something went wrong.."
        }
    }
    
    public var isError: Bool {
        switch self {
        case .custom:
            return false
        case .postNotFound:
            return true
        case .whoopsSomethingWentWrong:
            return true
        }
    }
    
    public var haptic: HapticType? {
        switch self {
        case .custom:
            return .none
        case .postNotFound,
             .whoopsSomethingWentWrong:
            return .error
        }
    }
}
