//
//  ForumEventLogFeature.swift
//  ForPDA
//
//  Created by Xialtal on 14.05.26.
//

import Foundation
import ComposableArchitecture
import APIClient
import Models
import ToastClient
import PasteboardClient

@Reducer
public struct ForumEventLogFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public let id: Int
        public let type: ForumEventLogType
        
        var eventLog: [ForumEventLog] = []
        var isLoading = false
        
        public init(
            id: Int,
            type: ForumEventLogType
        ) {
            self.id = id
            self.type = type
        }
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction {
        case view(View)
        public enum View {
            case onAppear
            
            case urlTapped(URL)
            case userButtonTapped(Int)
            
            case contextMenu(ForumEventLogContextMenuAction)
        }
        
        case `internal`(Internal)
        public enum Internal {
            case loadEventLog
            case eventLogResponse(Result<[ForumEventLog], any Error>)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case openUser(Int)
            case openTopic(Int)
            case handleUrl(URL)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.toastClient) private var toastClient
    @Dependency(\.pasteboardClient) private var pasteboardClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                return .send(.internal(.loadEventLog))
                
            case let .view(.urlTapped(url)):
                return .send(.delegate(.handleUrl(url)))
                
            case let .view(.userButtonTapped(id)):
                return .send(.delegate(.openUser(id)))
                
            case let .view(.contextMenu(action)):
                switch action {
                case .goToSubject:
                    switch state.type {
                    case .post:
                        let link = "https://4pda.to/forum/index.php?act=findpost&pid=\(state.id)"
                        return .send(.delegate(.handleUrl(URL(string: link)!)))
                    case .topic:
                        return .send(.delegate(.openTopic(state.id)))
                    }
                    
                case .copyLink:
                    let type = state.type == .post ? "p" : "t"
                    pasteboardClient.copy("https://4pda.to/forum/index.php?act=mod&code=90&\(type)=\(state.id)")
                    return .run { _ in
                        let message = ToastMessage(text: LocalizedStringResource("Link copied", bundle: .module), haptic: .success)
                        await toastClient.showToast(message)
                    }
                }
                
            case .internal(.loadEventLog):
                state.isLoading = true
                return .run { [id = state.id, type = state.type] send in
                    let response = try await apiClient.getForumEventLog(id, type)
                    await send(.internal(.eventLogResponse(.success(response))))
                } catch: { error, send in
                    await send(.internal(.eventLogResponse(.failure(error))))
                }
                
            case let .internal(.eventLogResponse(.success(response))):
                state.eventLog = response
                state.isLoading = false
                return .none
                
            case let .internal(.eventLogResponse(.failure(error))):
                print(error)
                state.isLoading = false
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
}

