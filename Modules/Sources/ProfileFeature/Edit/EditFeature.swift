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
    
    // MARK: - Localizations
    
    private enum Localization {
        static let avatarUpdated = LocalizedStringResource("Avatar updated", bundle: .module)
        static let avatarUpdateError = LocalizedStringResource("Avatar update error", bundle: .module)
        static let avatarFileSizeError = LocalizedStringResource("Avatar size more than 32KB", bundle: .module)
        static let avatarWidthHeightError = LocalizedStringResource("Avatar must be 100x100", bundle: .module)
    }
    
    // MARK: - Destinations
    
    @Reducer(state: .equatable)
    public enum Destination: Hashable, Equatable {
        case alert(AlertState<Alert>)
        case avatarPicker
        
        public enum Alert {
            case yes, no
        }
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public enum Field: CaseIterable { case status, signature, about, city }
        
        @Presents public var destination: Destination.State?
        
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
            return user.posts >= 250
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
                
            case .view(.onAppear):
                state.birthdayDate = state.draftUser.birthdayDate ?? nil
                return .none
                
            case .view(.avatarSelected(let data)):
                return .send(.internal(.updateAvatar(data)))
                
            case .view(.deleteAvatar):
                let empty = Data()
                return .send(.internal(.updateAvatar(empty)))
            
            case .view(.onAvatarBadFileSizeProvided):
                return showToast(ToastMessage(text: Localization.avatarFileSizeError, haptic: .error))
                
            case .view(.onAvatarBadWidthHeightProvided):
                return showToast(ToastMessage(text: Localization.avatarWidthHeightError, haptic: .error))
                
            case .view(.setBirthdayDate):
                state.birthdayDate = state.draftUser.birthdayDate ?? Date()
                return .none
                
            case .view(.wipeBirthdayDate):
                state.birthdayDate = nil
                return .none
                
            case .view(.saveButtonTapped):
                return .send(.internal(.saveProfile))
                
            case .delegate(.profileUpdated):
                return .run { _ in await dismiss() }
                
            case .view(.cancelButtonTapped):
                return .run { _ in await dismiss() }
                
            case .view(.addAvatarButtonTapped):
                state.destination = .avatarPicker
                return .none
                
            case .destination, .delegate:
                return .none
                
            case .internal(.saveProfile):
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
                    
                    return showToast(ToastMessage(text: Localization.avatarUpdated, haptic: .success))
                case .error:
                    return showToast(ToastMessage(text: Localization.avatarUpdateError, haptic: .error))
                }
                
            case let .internal(.updateAvatarResponse(.failure(error))):
                print("Error: \(error)")
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
    
    private func showToast(_ toast: ToastMessage) -> Effect<Action> {
        return .run { _ in
            await toastClient.showToast(toast)
        }
    }
}

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
