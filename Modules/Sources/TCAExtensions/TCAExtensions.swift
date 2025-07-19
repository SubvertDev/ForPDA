//
//  TCAExtensions.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 01.08.2024.
//

import UIKit
import ComposableArchitecture

// MARK: - AlertState

public extension AlertState {
    
    nonisolated(unsafe) static var somethingWentWrong: AlertState {
        AlertState {
            TextState("Whoops!", bundle: .module)
        } actions: {
            ButtonState(role: .cancel) { TextState("OK", bundle: .module) }
        } message: {
            TextState("Something went wrong... Try again later!", bundle: .module)
        }
    }
    
    nonisolated(unsafe) static var notImplemented: AlertState {
        AlertState {
            TextState("Whoops!", bundle: .module)
        } actions: {
            ButtonState(role: .cancel) { TextState("OK", bundle: .module) }
        } message: {
            TextState("Not yet implemented, but will be soon!", bundle: .module)
        }
    }
    
    nonisolated(unsafe) static var failedToConnect: AlertState {
        AlertState {
            TextState("Whoops!", bundle: .module)
        } actions: {
            ButtonState(role: .cancel) {
                TextState("OK")
            }
        } message: {
            TextState("Something went wrong while trying to connect to 4pda server...\nPlease try again later!", bundle: .module)
        }
    }
}

// MARK: - Open URL

public func open(url: URL) async {
    if #available(iOS 18, *) {
        Task { @MainActor in
            await UIApplication.shared.open(url)
        }
    } else {
        @Dependency(\.openURL) var openURL
        await openURL(url)
    }
}

// MARK: - Delay

public func delayUntilTimePassed(_ time: TimeInterval, since startTime: Date) async {
    let elapsedTime = Date().timeIntervalSince(startTime)
    if elapsedTime < time {
        let remainingTime = time - elapsedTime
        try? await Task.sleep(nanoseconds: UInt64(remainingTime * 1_000_000_000))
    }
}
