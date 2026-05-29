//
//  CreateChatFeature.swift
//  QMSListFeature
//
//  Created by Ilia Lubianoi on 16.05.2026.
//

import APIClient
import ComposableArchitecture
import Models
import QMSClient

@Reducer
public struct CreateChatFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - Enums
    
    enum Field {
        case username
        case chatTitle
        case message
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        var username = ""
        var chatTitle = ""
        var message = ""
        var focus: Field?

        var selectedSearchUser: SearchUsersResponse.SimplifiedUser?
        var searchUsers: [SearchUsersResponse.SimplifiedUser] = []
        var isSearchingUsers = false
        var shouldShowSearchUsers: Bool {
            return !searchUsers.isEmpty
        }
        
        public init(user: QMSUser? = nil) {
            self.username = user?.name ?? ""
            self.selectedSearchUser = user.map {
                SearchUsersResponse.SimplifiedUser(
                    id: $0.id,
                    name: $0.name,
                    groupId: 0,
                    avatarUrl: $0.avatarUrl?.absoluteString ?? ""
                )
            }
        }
    }
    
    // MARK: - Actions
    
    public enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        
        case view(View)
        public enum View {
            case viewTapped
            case searchUserSelected(SearchUsersResponse.SimplifiedUser)
            case sendButtonTapped
            case closeButtonTapped
        }
        
        case `internal`(Internal)
        public enum Internal {
            case searchUsername(String)
            case searchUsernameResult(Result<SearchUsersResponse, any Error>)
            case createChatResult(Result<String, any Error>)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case chatCreated(userId: Int)
        }
    }
    
    // MARK: - Depdendencies
    
    @Dependency(\.dismiss) private var dismiss
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.qmsClient) private var qmsClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
                
                // MARK: - Binding
                
            case .binding(\.username):
                state.selectedSearchUser = nil
                if !state.username.isEmpty, state.username.count >= 3 {
                    return .send(.internal(.searchUsername(state.username)))
                } else {
                    state.searchUsers.removeAll()
                }
                return .none
                
            case .binding:
                return .none
                
                // MARK: - View
                
            case .view(.viewTapped):
                state.focus = nil
                return .none
                
            case let .view(.searchUserSelected(user)):
                state.searchUsers.removeAll()
                state.username = user.name
                state.selectedSearchUser = user
                return .none
                
            case .view(.sendButtonTapped):
                guard let user = state.selectedSearchUser else { return .none }
                return .run { [title = state.chatTitle, message = state.message] send in
                    let response = try await qmsClient.createChat(opponentId: user.id, title: title, message: message)
                    await send(.internal(.createChatResult(.success(response))))
                } catch: { error, send in
                    await send(.internal(.createChatResult(.failure(error))))
                }
                
            case .view(.closeButtonTapped):
                return .run { _ in
                    await dismiss()
                }
                
                // MARK: - Internal
                
            case let .internal(.searchUsername(username)):
                state.searchUsers.removeAll()
                state.isSearchingUsers = true
                return .run { send in
                    let request = SearchUsersRequest(term: username, offset: 0, number: 12)
                    let result = try await apiClient.searchUsers(request)
                    await send(.internal(.searchUsernameResult(.success(result))))
                } catch: { error, send in
                    await send(.internal(.searchUsernameResult(.failure(error))))
                }
                
            case let .internal(.searchUsernameResult(.success(response))):
                state.searchUsers = response.users
                state.isSearchingUsers = false
                return .none
                
            case let .internal(.searchUsernameResult(.failure(error))):
                print(error)
                return .none
                
            case let .internal(.createChatResult(.success(result))):
                print("RESPONSE: \(result)")
                return .run { [userId = state.selectedSearchUser!.id] send in
                    await send(.delegate(.chatCreated(userId: userId)))
                    await dismiss()
                }
                
            case let .internal(.createChatResult(.failure(error))):
                print(error)
                return .none
                
                // MARK: - Delegate
                
            case .delegate:
                return .none
            }
        }
    }
}
