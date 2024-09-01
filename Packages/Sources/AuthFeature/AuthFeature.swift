//
//  AuthFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 01.08.2024.
//

import Foundation
import ComposableArchitecture
import TCAExtensions
import APIClient
import PersistenceKeys
import Models

@Reducer
public struct AuthFeature: Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public enum Field { case login, password, captcha }
        
        @Presents public var alert: AlertState<Action.Alert>?
        public var isLoading: Bool
        public var login: String
        public var password: String
        public var isHiddenEntry: Bool
        public var captchaUrl: URL?
        public var captcha: String
        public var focus: Field?
        
        public var isLoginButtonDisabled: Bool {
            return login.isEmpty || password.isEmpty || captcha.count < 4 || isLoading
        }
        
        public init(
            isLoading: Bool = true,
            login: String = "",
            password: String = "",
            isHiddenEntry: Bool = false,
            captchaUrl: URL? = nil,
            captcha: String = "",
            focus: Field? = nil
        ) {
            self.isLoading = isLoading
            self.login = login
            self.password = password
            self.isHiddenEntry = isHiddenEntry
            self.captchaUrl = captchaUrl
            self.captcha = captcha
            self.focus = focus
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case loginButtonTapped
        case onTask
        case onSubmit(State.Field)
        
        case _captchaResponse(Result<URL, any Error>)
        case _loginResponse(Result<AuthResponse, any Error>)
        case _wrongPassword
        case _wrongCaptcha(url: URL)
        
        case alert(PresentationAction<Alert>)
        public enum Alert {
            case cancel
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case loginSuccess(userId: Int)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
                
                // MARK: - External
                
            case .alert:
                state.alert = nil
                return .none
                
            case .binding:
                return .none
                
            case .delegate:
                return .none
            
            case .onSubmit(let field):
                switch field {
                case .login:    state.focus = .password
                case .password: state.focus = .captcha
                case .captcha:  state.focus = nil
                }
                return .none
                
            case .loginButtonTapped:
                state.isLoading = true
                return .run { [
                    login = state.login,
                    password = state.password,
                    isHiddenEntry = state.isHiddenEntry,
                    captcha = state.captcha
                ] send in
                    // TODO: Rename name to login
                    do {
                        let response = try await apiClient.authorize(login, password, isHiddenEntry, Int(captcha)!)
                        await send(._loginResponse(.success(response)))
                    } catch {
                        await send(._loginResponse(.failure(error)))
                    }
                }
                
            case .onTask:
                return .run { send in
                    let result = await Result { try await apiClient.getCaptcha() }
                    await send(._captchaResponse(result))
                }
                .animation()
                
                // MARK: - Internal
                
            case ._captchaResponse(let response):
                state.isLoading = false
                switch response {
                case .success(let url):
                    state.captchaUrl = url
                case .failure(let error):
                    print(error, #line)
                    state.alert = .failedToConnect
                }
                return .none
                
            case ._loginResponse(.success(let loginState)):
                state.isLoading = false
                return .run { [isHidden = state.isHiddenEntry] send in
                    switch loginState {
                    case .success(userId: let userId, token: let token):
                        @Shared(.userSession) var userSession
                        await $userSession.withLock { $0 = UserSession(userId: userId, token: token, isHidden: isHidden) }
                        await send(.delegate(.loginSuccess(userId: userId)))
                        
                    case .wrongPassword:
                        await send(._wrongPassword)
                        
                    case .wrongCaptcha(let url):
                        await send(._wrongCaptcha(url: url))
                        
                    case .unknown:
                        fatalError("unknown login response type")
                    }
                }
                
            case ._loginResponse(.failure(let error)):
                state.isLoading = false
                print(error, #line)
                state.alert = .failedToConnect
                return .none
                
            case ._wrongPassword:
                state.password = ""
                state.captcha = ""
                state.focus = .password
                state.alert = .wrongPassword
                return .run { send in
                    let result = await Result { try await apiClient.getCaptcha() }
                    await send(._captchaResponse(result))
                }

            case let ._wrongCaptcha(url: url):
                state.captcha = ""
                state.captchaUrl = url
                state.focus = .captcha
                state.alert = .wrongCaptcha
                return .none
            }
        }
        
        Analytics()
    }
}

// MARK: - AlertState extension

extension AlertState where Action == AuthFeature.Action.Alert {
        
    nonisolated(unsafe) static var wrongPassword: AlertState {
        AlertState {
            TextState("Whoops!", bundle: .module)
        } actions: {
            ButtonState(role: .cancel) {
                TextState("OK", bundle: .module)
            }
        } message: {
            TextState("Login or pasword is wrong, try again", bundle: .module)
        }
    }
    
    nonisolated(unsafe) static var wrongCaptcha: AlertState {
        AlertState {
            TextState("Whoops!", bundle: .module)
        } actions: {
            ButtonState(role: .cancel) {
                TextState("OK", bundle: .module)
            }
        } message: {
            TextState("Captcha is wrong, try again", bundle: .module)
        }
    }
}
