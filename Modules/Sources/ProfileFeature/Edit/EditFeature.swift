//
//  EditFeature.swift
//  ForPDA
//
//  Created by Xialtal on 28.08.25.
//

import Foundation
import ComposableArchitecture
import APIClient
import Models
import ToastClient

@Reducer
public struct EditFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - Destinations
    
    @Reducer
    public enum Destination: Hashable, Equatable {
        case avatarPicker
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public enum Field: CaseIterable { case status, signature, about, city }
        
        @Presents public var destination: Destination.State?
        @Presents public var alert: AlertState<Action.Alert>?
        
        let user: User
        var draftUser: User
        var focus: Field?
        
        var isSending = false
        var isAvatarUploading = false
        
        var birthdayDate: Date?
        
        var isUserSetAvatar: Bool {
            return draftUser.imageUrl != Links.defaultAvatar
        }
        
        var isUserSetBirhdayDate: Bool {
            return user.birthdayDate != nil
        }
        
        var isUserCanEditStatus: Bool {
            return user.replies >= 250
        }
        
        var isSavingDisabled: Bool {
            return isUserInfoFieldsEqual
                && draftUser.devDBdevices == user.devDBdevices
        }
        
        var isUserInfoFieldsEqual: Bool {
            return draftUser.city == user.city
                && draftUser.aboutMe == user.aboutMe
                && draftUser.status == user.status
                && draftUser.gender == user.gender
                && draftUser.signature == user.signature
                && draftUser.birthdayDate == birthdayDate
        }
        
        public init(user: User) {
            self.user = user
            self.draftUser = user
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        case destination(PresentationAction<Destination.Action>)
        
        case view(View)
        public enum View {
            case onAppear
            case avatarSelected(Data)
            case deleteAvatar
            
            case onAvatarBadFileSizeProvided
            case onAvatarBadWidthHeightProvided
            
            case wipeBirthdayDate
            case setBirthdayDate
            
            case saveButtonTapped
            case cancelButtonTapped
            case addAvatarButtonTapped
        }
        
        case alert(PresentationAction<Alert>)
        public enum Alert {
            case cancel
            case deleteAvatar
        }
        
        case `internal`(Internal)
        public enum Internal {
            case saveProfile
            case updateAvatar(Data)
            case updateAvatarResponse(Result<UserAvatarResponseType, any Error>)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case profileUpdated(Bool)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.dismiss) private var dismiss
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.toastClient) private var toastClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none
                
            case .alert(.presented(.deleteAvatar)):
                let empty = Data()
                return .send(.internal(.updateAvatar(empty)))
                
            case .view(.onAppear):
                state.birthdayDate = state.draftUser.birthdayDate ?? nil
                return .none
                
            case .view(.avatarSelected(let data)):
                return .send(.internal(.updateAvatar(data)))
                
            case .view(.deleteAvatar):
                state.alert = .deleteAvatarConfirmation
                return .none
            
            case .view(.onAvatarBadFileSizeProvided):
                state.alert = .avatarFileSizeError
                return .none
                
            case .view(.onAvatarBadWidthHeightProvided):
                state.alert = .avatarWidthHeightError
                return .none
                
            case .view(.setBirthdayDate):
                state.birthdayDate = state.draftUser.birthdayDate ?? Date()
                return .none
                
            case .view(.wipeBirthdayDate):
                state.birthdayDate = nil
                return .none
                
            case .view(.saveButtonTapped):
                return .send(.internal(.saveProfile))
                
            case .delegate(.profileUpdated):
                state.isSending = false
                return .run { _ in await dismiss() }
                
            case .view(.cancelButtonTapped):
                return .run { _ in await dismiss() }
                
            case .view(.addAvatarButtonTapped):
                state.destination = .avatarPicker
                return .none
                
            case .alert:
                state.alert = nil
                return .none
                
            case .destination, .delegate:
                return .none
                
            case .internal(.saveProfile):
                state.isSending = true
                return .run { [user = state.draftUser, birthdayDate = state.birthdayDate] send in
                    let status = try await apiClient.editUserProfile(UserProfileEditRequest(
                        userId: user.id,
                        city: user.city ?? "",
                        about: user.aboutMe?.simplify() ?? "",
                        gender: user.gender ?? .unknown,
                        status: user.status ?? "",
                        signature: user.signature?.simplify() ?? "",
                        birthdayDate: birthdayDate
                    ))
                    await send(.delegate(.profileUpdated(status)))
                }
                
            case .internal(.updateAvatar(let data)):
                state.isAvatarUploading = true
                return .run { [userId = state.user.id] send in
                    let response = try await apiClient.updateUserAvatar(userId, data)
                    await send(.internal(.updateAvatarResponse(.success(response))))
                }
                
            case let .internal(.updateAvatarResponse(.success(response))):
                switch response {
                case .success(let url):
                    state.draftUser.imageUrl = url ?? Links.defaultAvatar
                    state.isAvatarUploading = false
                case .error:
                    state.alert = .avatarUpdateError
                }
                return .none
                
            case let .internal(.updateAvatarResponse(.failure(error))):
                print("Error: \(error)")
                return .none
            }
        }
        .ifLet(\.alert, action: \.alert)
        .ifLet(\.$destination, action: \.destination)
    }
}

extension EditFeature.Destination.State: Equatable {}

// MARK: - Alert Extension

private extension AlertState where Action == EditFeature.Action.Alert {
    nonisolated(unsafe) static let avatarUpdateError = Self {
        TextState("Avatar update error", bundle: .module)
    } actions: {
        ButtonState(role: .cancel) {
            TextState("Ok", bundle: .module)
        }
    }
    
    nonisolated(unsafe) static let avatarFileSizeError = Self {
        TextState("Avatar size more than 32KB", bundle: .module)
    } actions: {
        ButtonState(role: .cancel) {
            TextState("Ok", bundle: .module)
        }
    }
    
    nonisolated(unsafe) static let avatarWidthHeightError = Self {
        TextState("Avatar must be 100x100", bundle: .module)
    } actions: {
        ButtonState(role: .cancel) {
            TextState("Ok", bundle: .module)
        }
    }
    
    nonisolated(unsafe) static let deleteAvatarConfirmation = Self {
        TextState("Are you sure, that you want to delete an avatar?", bundle: .module)
    } actions: {
        ButtonState(role: .cancel) {
            TextState("Cancel", bundle: .module)
        }
        
        ButtonState(role: .destructive, action: .deleteAvatar) {
            TextState("Delete", bundle: .module)
        }
    }
}

// MARK: - Helpers

private extension Date {
    func toProfileString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        return dateFormatter.string(from: self)
    }
}

private extension String {
    func simplify() -> String {
        return String(self.debugDescription.dropFirst().dropLast())
    }
}
