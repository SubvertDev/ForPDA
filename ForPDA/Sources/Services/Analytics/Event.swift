//
//  Event.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 04.11.2023.
//

enum Event {

    enum News: String {
        case articleOpen
        case newsLinkCopied
        case newsLinkShared
        case newsReport
        case menuOpen
    }
    
    enum Article: String {
        case articleLinkCopied
        case articleLinkShared
        case articleReport
        case articleLinkClicked
        case articleButtonClicked
    }
    
    enum Menu: String {
        case loginOpen
        case profileOpen
        case historyOpen // (todo) not working yet!
        case bookmarksOpen // (todo) not working yet!
        case settingsOpen
        case author4PDAOpen
        case discussion4PDAOpen // (todo) not working yet!
        case newsTelegramOpen
        case chatTelegramOpen
        case githubOpen
    }
    
    enum Login: String {
        case loginSuccess
        case loginFailed
    }
    
    enum Profile: String {
        case profileLogout
    }
    
    enum Settings: String {
        case languageOpen
        case themeOpen
        case themeChanged
        case nightModeOpen
        case nightModeChanged
        case fastLoadingSystemChanged
        case showLikesChanged
    }
    
}
