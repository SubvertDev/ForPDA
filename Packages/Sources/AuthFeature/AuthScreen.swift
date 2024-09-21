//
//  AuthScreen.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 01.08.2024.
//

import SwiftUI
import ComposableArchitecture
import SharedUI
import NukeUI
import SFSafeSymbols

public struct AuthScreen: View {
    
    @Perception.Bindable public var store: StoreOf<AuthFeature>
    @Environment(\.tintColor) private var tintColor
    @FocusState public var focus: AuthFeature.State.Field?
    @State private var animateOnFocus = [false, false, false]
    
    public init(store: StoreOf<AuthFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color.Background.primary
                
                ScrollView {
                    VStack(spacing: 0) {
                        Image.logoLight
                            .resizable()
                            .frame(width: 104, height: 104)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.Separator.primary, lineWidth: 0.33)
                            )
                            .padding(.top, 16)
                            .padding(.bottom, 12)
                        
                        Text("Welcome back!", bundle: .module)
                            .font(.title2)
                            .bold()
                            .foregroundStyle(Color.Labels.primary)
                            .padding(.bottom, 28)
                        
                        VStack(spacing: 16) {
                            Field(
                                symbol: .personCropCircle,
                                text: $store.login,
                                placeholder: "Login",
                                focusEqual: .login,
                                onSubmit: { store.send(.onSubmit(.login)) }
                            )
                            .bounceUpByLayerEffect(value: animateOnFocus[0])
                            
                            Field(
                                symbol: .lock,
                                text: $store.password,
                                placeholder: "Password",
                                focusEqual: .password,
                                isSecure: true,
                                errorMessage: "Login or password is incorrect",
                                showError: store.loginErrorReason == .wrongLoginOrPassword,
                                onSubmit: { store.send(.onSubmit(.password)) }
                            )
                            .bounceUpByLayerEffect(value: animateOnFocus[1])
                            
                            Toggle(isOn: $store.isHiddenEntry) {
                                Text("Hidden entry", bundle: .module)
                                    .font(.body)
                                    .foregroundStyle(Color.Labels.teritary)
                            }
                            .tint(tintColor)
                            .padding(.horizontal, 12)
                        }
                        .padding(.bottom, 28)
                        
                        Rectangle()
                            .fill(.clear)
                            .aspectRatio(1.6, contentMode: .fit)
                            .overlay {
                                if let captchaUrl = store.captchaUrl {
                                    LazyImage(url: captchaUrl) { state in
                                        if let image = state.image {
                                            image.resizable().aspectRatio(1.6, contentMode: .fit)
                                        }
                                    }
                                } else {
                                    HStack { ProgressView() }
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.Separator.primary, lineWidth: 0.33)
                            )
                            .frame(height: 124)
                            .padding(.bottom, 16)
                        
                        Field(
                            symbol: .numberSquare,
                            text: $store.captcha,
                            placeholder: "Enter captcha",
                            focusEqual: .captcha,
                            errorMessage: "Captcha is incorrect",
                            showError: store.loginErrorReason == .wrongCaptcha,
                            onSubmit: { store.send(.onSubmit(.captcha)) }
                        )
                        .bounceUpByLayerEffect(value: animateOnFocus[2])
                        .keyboardType(.numberPad)
                        .onChange(of: store.captcha) { _ in
                            store.captcha = String(store.captcha.prefix(4))
                        }
                        .padding(.bottom, 80)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                }
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    Button {
                        store.send(.loginButtonTapped)
                    } label: {
                        Text("Log in", bundle: .module)
                            .font(.body)
                            .frame(maxWidth: .infinity, maxHeight: 48)
                    }
                    .frame(maxHeight: 48)
                    .buttonStyle(.borderedProminent)
                    .disabled(store.isLoginButtonDisabled)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.Background.primary)
                    .tint(tintColor)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        store.send(.cancelButtonTapped)
                    } label: {
                        Text("Cancel", bundle: .module)
                            .foregroundStyle(tintColor)
                    }
                }
            }
            .alert($store.scope(state: \.alert, action: \.alert))
            .bind($store.focus, to: $focus)
            .onChange(of: focus) { _ in
                // TODO: Redo
                switch focus {
                case .login:    animateOnFocus[0].toggle()
                case .password: animateOnFocus[1].toggle()
                case .captcha:  animateOnFocus[2].toggle()
                case nil:       break
                }
            }
            .task {
                store.send(.onTask)
            }
        }
    }
    
    // MARK: - Field
    
    @ViewBuilder
    private func Field(
        symbol: SFSymbol,
        text: Binding<String>,
        placeholder: LocalizedStringKey,
        focusEqual: AuthFeature.State.Field,
        isSecure: Bool = false,
        errorMessage: LocalizedStringKey? = nil,
        showError: Bool = false,
        onSubmit: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemSymbol: symbol)
                    .font(.body)
                    .foregroundStyle(tintColor)
                    .frame(width: 32, height: 32)
                
                Group {
                    if isSecure {
                        SecureField(text: text) {
                            Text(placeholder, bundle: .module)
                                .font(.body)
                                .foregroundStyle(Color.Labels.quaternary)
                        }
                    } else {
                        TextField(text: text) {
                            Text(placeholder, bundle: .module)
                                .font(.body)
                                .foregroundStyle(Color.Labels.quaternary)
                        }
                    }
                }
                .font(.body)
                .foregroundStyle(Color.Labels.primary)
                .focused($focus, equals: focusEqual)
                .onSubmit { onSubmit() }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.Background.teritary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke($focus.wrappedValue == focusEqual ? tintColor : Color.Separator.primary, lineWidth: 0.67)
            )
            
            if let errorMessage, showError {
                Text(errorMessage, bundle: .module)
                    .font(.caption)
                    .foregroundStyle(Color.Main.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 12)
            }
        }
        .animation(.default, value: showError)
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        AuthScreen(
            store: Store(
                initialState: AuthFeature.State(openReason: .profile)
            ) {
                AuthFeature()
            } withDependencies: {
                $0.apiClient = .previewValue
            }
        )
    }
    .environment(\.tintColor, Color.Theme.primary)
}

#Preview("Wrong Credentials") {
    NavigationStack {
        AuthScreen(
            store: Store(
                initialState: AuthFeature.State.init(
                    openReason: .profile,
                    login: "TestLogin",
                    password: "TestPassword",
                    captcha: "1234"
                )
            ) {
                AuthFeature()
            } withDependencies: {
                $0.apiClient.getCaptcha = { return URL(string: "/")! }
                $0.apiClient.authorize = { @Sendable _, _, _, _ in
                    try? await Task.sleep(for: .seconds(1))
                    return .wrongPassword
                }
            }
        )
    }
    .environment(\.tintColor, Color.Theme.primary)
}
