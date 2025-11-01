//
//  FavoritesEvent.swift
//  AnalyticsClient
//
//  Created by Ilia Lubianoi on 20.03.2025.
//

import Foundation

public enum FavoritesEvent: Event {
    case onRefresh
    case favoriteTapped(Int, String, Int?, Bool, Bool)
    
    case sortButtonTapped
    case readAllButtonTapped
    
    case setImportant(Int, Bool)
    case markRead(Int, Bool)
    case linkCopied(Int, Bool)
    case delete(Int)
    
    case goToEnd(Int)
    case notify(Int, Int, String)
    case notifyHatUpdate(Int)
    
    case sortDismissed
    case sortSaveButtonTapped
    case sortCancelButtonTapped
    case sortTypeSelected(String)
    
    case loadingStart(Int)
    case loadingSuccess
    case loadingFailure(any Error)
    case startUnreadLoadingIndicator(Int)
    
    public var name: String {
        return "Favorites " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String]? {
        switch self {
        case let .favoriteTapped(id, name, postId, isForum, showUnread):
            return [
                "id": String(id),
                "name": name,
                "postId": postId.map { String($0) } ?? "nil",
                "isForum": isForum.description,
                "showUnread": showUnread.description
            ]
            
        case let .setImportant(id, isForum),
            let .markRead(id, isForum),
            let .linkCopied(id, isForum):
            return ["id": String(id), "isForum": isForum.description]
            
        case let .delete(id):
            return ["id": String(id)]
            
        case let .goToEnd(id):
            return ["id": String(id)]
            
        case let .notify(id, flag, type):
            return ["id": String(id), "flag": String(flag), "type": type]
            
        case let .notifyHatUpdate(id):
            return ["id": String(id)]
            
        case let .sortTypeSelected(type):
            return ["type": type]
            
        case let .loadingStart(offset):
            return ["offset": String(offset)]
            
        case let .loadingFailure(error):
            return ["error": error.localizedDescription]
            
        case let .startUnreadLoadingIndicator(id):
            return ["id": String(id)]
            
        default:
            return nil
        }
    }
}
