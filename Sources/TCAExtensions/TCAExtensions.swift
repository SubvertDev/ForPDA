//
//  TCAExtensions.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 01.08.2024.
//

import ComposableArchitecture

public extension AlertState {
    
    nonisolated(unsafe) static var notImplemented: AlertState {
        AlertState {
            TextState("Whoops!", bundle: .module)
        } actions: {
            ButtonState(role: .cancel) { TextState("OK", bundle: .module) }
        } message: {
            TextState("Not yet implemented :(", bundle: .module)
        }
    }
    
    nonisolated(unsafe) static var failedToConnect: AlertState {
        AlertState {
            TextState("Whoops!")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("OK")
            }
        } message: {
            TextState("Something went wrong while trying to connect to 4pda server...\nPlease try again later!")
        }
    }
}
