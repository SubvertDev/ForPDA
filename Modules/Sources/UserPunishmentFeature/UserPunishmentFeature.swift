//
//  UserPunishmentFeature.swift
//  ForPDA
//
//  Created by Xialtal on 28.06.26.
//

import Foundation
import ComposableArchitecture
import APIClient
import Models

@Reducer
public struct UserPunishmentFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - Alert
    
    public enum Alert {
        case forceApply
        case doNotForceApply
        case dismiss
        case ok
    }
    
    // MARK: - Pickers
    
    enum DateFormatPicker {
        case days
        case hours
    }
    
    enum BanTypePicker {
        case no
        case permanent
        case lastChanse
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var alert: AlertState<Alert>?
        
        public enum Field: Hashable {
            case reason
            case message
            case premod
            case readOnly
        }
        
        public let userId: Int
        public let target: UserPunishmentTarget
        
        var categories: IdentifiedArrayOf<UserPunishmentCategory> = []
        var currentCategory: UIUserPunishmentCategory
        
        var focus: Field?
        var banType: BanTypePicker = .no
        var premodDateFormat: DateFormatPicker = .hours
        var readOnlyDateFormat: DateFormatPicker = .hours
        
        var isLoading = false
        var isSending = false
        
        var isApplyButtonDisabled: Bool {
            return false
        }
        
        public init(
            userId: Int,
            target: UserPunishmentTarget
        ) {
            self.userId = userId
            self.target = target
            
            self.currentCategory = .default
        }
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction, BindableAction {
        case binding(BindingAction<State>)
        case alert(PresentationAction<Alert>)
        
        case view(View)
        public enum View {
            case onAppear
            
            case applyButtonTapped
            case cancelButtonTapped
            
            case updateCategory(id: String)
            case updateTemplate(id: String)
            
            case updateTemplatePremodValue(String)
            case updateTemplateReadOnlyValue(String)
            
            case configurePickers
        }
        
        case `internal`(Internal)
        public enum Internal {
            case loadTemplates(forId: Int)
            case templatesResponse(Result<[UserPunishmentCategory], any Error>)
            case applyPunishment
            case applyPunishmentResponse(Result<UserPunishmentApplyResponse, any Error>)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case punishmentApplied(UserPunishmentTarget)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.dismiss) private var dismiss
    @Dependency(\.apiClient) private var apiClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case .binding(\.banType):
                switch state.banType {
                case .no:
                    state.currentCategory.template.flag.remove([.fullBan, .lastChance])
                case .permanent:
                    state.currentCategory.template.flag.remove([.lastChance])
                    state.currentCategory.template.flag.insert([.fullBan])
                case .lastChanse:
                    state.currentCategory.template.flag.remove([.fullBan])
                    state.currentCategory.template.flag.insert([.lastChance])
                }
                return .none
                
            case .binding(\.premodDateFormat):
                let value = switch state.premodDateFormat {
                case .days: state.currentCategory.template.premoderationHours / 24
                case .hours: state.currentCategory.template.premoderationHours * 24
                }
                state.currentCategory.template.premoderationHours = value
                return .none
                
            case .binding(\.readOnlyDateFormat):
                let value = switch state.readOnlyDateFormat {
                case .days: state.currentCategory.template.readOnlyHours / 24
                case .hours: state.currentCategory.template.readOnlyHours * 24
                }
                state.currentCategory.template.readOnlyHours = value
                return .none
                
            case let .alert(.presented(action)):
                switch action {
                case .forceApply:
                    state.currentCategory.template.flag.insert(.forceApply)
                    return .send(.internal(.applyPunishment))
                case .doNotForceApply:
                    state.currentCategory.template.flag.remove(.forceApply)
                    return .none
                case .dismiss:
                    return .run { _ in await dismiss() }
                case .ok:
                    return .none
                }
                
            case .alert(.dismiss):
                state.isSending = false
                return .none
                
            case .delegate, .binding, .alert:
                return .none
                
            case .view(.onAppear):
                return .send(.internal(.loadTemplates(forId: state.target.id)))
                
            case .view(.applyButtonTapped):
                return .send(.internal(.applyPunishment))
                
            case .view(.cancelButtonTapped):
                return .run { _ in await dismiss() }
                
            case let .view(.updateCategory(id)):
                if let category = state.categories[id: id], let template = category.templates.first {
                    state.currentCategory = UIUserPunishmentCategory(
                        id: category.id,
                        title: category.title,
                        supportsRestrictions: category.supportsRestrictions,
                        template: template
                    )
                    return .send(.view(.configurePickers))
                }
                return .none
                
            case let .view(.updateTemplate(id)):
                if let category = state.categories[id: state.currentCategory.id],
                   let template = category.templates.first(where: { $0.id == id }) {
                    state.currentCategory.template = template
                    return .send(.view(.configurePickers))
                }
                return .none
                
            case .view(.configurePickers):
                state.currentCategory.template.readOnlyHours /= state.readOnlyDateFormat == .days ? 24 : 1
                state.currentCategory.template.premoderationHours /= state.premodDateFormat == .days ? 24 : 1
                state.banType = if state.currentCategory.template.flag.contains(.lastChance) {
                    .lastChanse
                } else if state.currentCategory.template.flag.contains(.fullBan) {
                    .permanent
                } else {
                    .no
                }
                return .none
                
            case let .view(.updateTemplatePremodValue(value)):
                state.currentCategory.template.premoderationHours = Int(value) ?? 0
                if state.currentCategory.template.premoderationHours != 0 {
                    state.currentCategory.template.flag.insert(.addCurrentPremod)
                } else {
                    state.currentCategory.template.flag.remove(.addCurrentPremod)
                }
                return .none
                
            case let .view(.updateTemplateReadOnlyValue(value)):
                state.currentCategory.template.readOnlyHours = Int(value) ?? 0
                if state.currentCategory.template.readOnlyHours != 0 {
                    state.currentCategory.template.flag.insert(.addCurrentRO)
                } else {
                    state.currentCategory.template.flag.remove(.addCurrentRO)
                }
                return .none
                
            case .internal(.applyPunishment):
                state.isSending = true
                return .run { [
                    subjectId = state.target.id,
                    userId = state.userId,
                    category = state.currentCategory
                ] send in
                    let request = UserPunishmentApplyRequest(
                        userId: userId,
                        subjectId: subjectId,
                        categoryId: category.id,
                        template: category.template
                    )
                    let response = try await apiClient.applyUserPunishment(request)
                    await send(.internal(.applyPunishmentResponse(.success(response))))
                } catch: { error, send in
                    await send(.internal(.applyPunishmentResponse(.failure(error))))
                }
                
            case let .internal(.applyPunishmentResponse(.success(status))):
                switch status {
                case .success:
                    return .send(.delegate(.punishmentApplied(state.target)))
                case .reasonNotSet:
                    state.alert = .reasonNotSet
                case .messageNotSet:
                    state.alert = .messageNotSet
                case .warningLevelMax:
                    state.alert = .warningLevelMax
                case .needConfirmation:
                    state.alert = .forceApplyConfirmation
                case .noAccess:
                    state.alert = .unknownError
                }
                state.isSending = false
                return .none
                
            case let .internal(.applyPunishmentResponse(.failure(error))):
                print(error)
                state.alert = .unknownError
                return .none
                
            case let .internal(.loadTemplates(forId)):
                state.isLoading = true
                return .run { [userId = state.userId] send in
                    let response = try await apiClient.getUserPunishmentTemplates(forId, userId)
                    await send(.internal(.templatesResponse(.success(response))))
                } catch: { error, send in
                    await send(.internal(.templatesResponse(.failure(error))))
                }
                
            case let .internal(.templatesResponse(.success(response))):
                state.categories = .init(uniqueElements: response)
                
                if let category = response.first, let template = category.templates.first {
                    state.currentCategory = UIUserPunishmentCategory(
                        id: category.id,
                        title: category.title,
                        supportsRestrictions: category.supportsRestrictions,
                        template: template
                    )
                    state.isLoading = false
                } else {
                    state.alert = .unknownError
                }
                return .none
                
            case let .internal(.templatesResponse(.failure(error))):
                print(error)
                state.isLoading = false
                state.alert = .unknownError
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

// MARK: - Alerts

public extension AlertState where Action == UserPunishmentFeature.Alert {
    
    nonisolated(unsafe) static let forceApplyConfirmation = AlertState {
        TextState("This user's warning level has already been raised within the last 5 hours", bundle: .module)
    } actions: {
        ButtonState(role: .destructive, action: .forceApply) {
            TextState("Raise", bundle: .module)
        }
        ButtonState(role: .cancel, action: .doNotForceApply) {
            TextState("Cancel", bundle: .module)
        }
    } message: {
        TextState("Confirm punishment", bundle: .module)
    }
    
    nonisolated(unsafe) static let warningLevelMax = AlertState {
        TextState("The warning level is already at its maximum", bundle: .module)
    } actions: {
        ButtonState(action: .dismiss) {
            TextState("OK")
        }
    }
    
    nonisolated(unsafe) static let messageNotSet = AlertState {
        TextState("No message specified", bundle: .module)
    } actions: {
        ButtonState(action: .ok) {
            TextState("OK")
        }
    }
    
    nonisolated(unsafe) static let reasonNotSet = AlertState {
        TextState("Reason not specified", bundle: .module)
    } actions: {
        ButtonState(action: .ok) {
            TextState("OK")
        }
    }
    
    nonisolated(unsafe) static let unknownError = AlertState {
        TextState("Unknown error", bundle: .module)
    } actions: {
        ButtonState(action: .dismiss) {
            TextState("OK")
        }
    }
}
