//
//  AuthScreen.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 01.08.2024.
//

import SwiftUI
import ComposableArchitecture
import NukeUI

public struct AuthScreen: View {
    
    @Perception.Bindable public var store: StoreOf<AuthFeature>
    @FocusState public var focus: AuthFeature.State.Field?
    
    public init(store: StoreOf<AuthFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 0) {
                Form {
                    Section {
                        TextField(text: $store.login) {
                            Text("Login", bundle: .module)
                        }
                        .focused($focus, equals: .login)
                        .onSubmit { store.send(.onSumbit(.login)) }
                        
                        SecureField(text: $store.password) {
                            Text("Password", bundle: .module)
                        }
                        .focused($focus, equals: .password)
                        .onSubmit { store.send(.onSumbit(.password)) }
                        
                        Toggle(isOn: $store.isHiddenEntry) {
                            Text("Hidden entry", bundle: .module)
                        }
                    }
                    
                    Section {
                        Rectangle()
                            .fill(.clear)
                            .aspectRatio(2.4, contentMode: .fit)
                            .overlay {
                                if let captchaUrl = store.captchaUrl {
                                    LazyImage(url: captchaUrl) { state in
                                        if let image = state.image {
                                            image.resizable().aspectRatio(2.4, contentMode: .fit)
                                        }
                                    }
                                } else {
                                    HStack { ProgressView() }
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        
                        TextField(text: $store.captcha) {
                            Text("Captcha", bundle: .module)
                        }
                        .focused($focus, equals: .captcha)
                        .onSubmit { store.send(.onSumbit(.captcha)) }
                        .keyboardType(.numberPad)
                        // TODO: Not working in reducer smh
                        .onChange(of: store.captcha) { _ in
                            store.captcha = String(store.captcha.prefix(4))
                        }
                    }
                    
                    Section {
                        Button {
                            store.send(.loginButtonTapped)
                        } label: {
                            Text("Log in", bundle: .module)
                        }
                        .disabled(store.isLoginButtonDisabled)
                    }
                }
            }
            .navigationTitle(Text("Authhorization", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .alert($store.scope(state: \.alert, action: \.alert))
            .bind($store.focus, to: $focus)
            .task {
                store.send(.onTask)
            }
        }
    }
}

#Preview {
    NavigationStack {
        AuthScreen(
            store: Store(
                initialState: AuthFeature.State()
            ) {
                AuthFeature()
            } withDependencies: {
                $0.apiClient = .previewValue
            }
        )
    }
}
