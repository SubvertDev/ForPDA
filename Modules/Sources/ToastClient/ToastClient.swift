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

    // Posts
    case postNotFound
    case postDeleted
    
    // Topics
    case topicSent
    case topicFieldsError
    case topicBadParameter
    case topicSentToPremoderation
    case topicStatus(Int)
    
    // Report
    case reportSent
    case reportTooShort
    case reportSendError
    
    // Common
    case whoopsSomethingWentWrong
    
    public var description: LocalizedStringKey {
        switch self {
        case .custom(let text):
            return LocalizedStringKey(text)
        case .postNotFound:
            return "Post not found"
        case .postDeleted:
            return "Post deleted"
        case .topicSent:
            return "Topic sent"
        case .topicFieldsError:
            return "There were errors in filling out the form"
        case .topicBadParameter:
            return "The server refused to create the topic (invalid parameter)"
        case .topicSentToPremoderation:
            return "Topic sent to pre-moderation"
        case .topicStatus(let status):
            return "Topic sending error. Status \(status)"
        case .reportSent:
            return "Report sent"
        case .reportTooShort:
            return "Report too short"
        case .reportSendError:
            return "Error sending report"
        case .whoopsSomethingWentWrong:
            return "Whoops, something went wrong.."
        }
    }
    
    public var isError: Bool {
        switch self {
        case .postNotFound,
             .reportTooShort,
             .reportSendError,
             .topicStatus,
             .topicBadParameter,
             .topicFieldsError,
             .topicSentToPremoderation,
             .whoopsSomethingWentWrong:
			return true

        case .custom, .reportSent, .postDeleted, .topicSent:
            return false
        }
    }
    
    public var haptic: HapticType? {
        switch self {
        case .custom:
            return .none

        case .postNotFound,
             .reportTooShort,
             .reportSendError,
             .topicStatus,
             .topicBadParameter,
             .topicFieldsError,
             .topicSentToPremoderation,
             .whoopsSomethingWentWrong:
            return .error
            
        case .reportSent, .postDeleted, .topicSent:
            return .success
        }
    }
}
