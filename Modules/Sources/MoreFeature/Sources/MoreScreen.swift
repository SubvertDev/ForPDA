//
//  MoreScreen.swift
//  MoreFeature
//
//  Created by Ilia Lubianoi on 02.05.2026.
//

import AuthFeature
import ComposableArchitecture
import Models
import NukeUI
import SFSafeSymbols
import SharedUI
import SwiftUI

@ViewAction(for: MoreFeature.self)
public struct MoreScreen: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<MoreFeature>
    
    @Environment(\.tintColor) private var tintColor
    
    // MARK: - Init
    
    public init(store: StoreOf<MoreFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                List {
                    ProfileSection()
                    NavigationSection()
                    SettingsSection()
                    LinksSection()
                    LogoutSection()
                }
                .scrollContentBackground(.hidden)
            }
            .overlay {
                if store.isLoading {
                    PDALoader()
                        .frame(width: 24, height: 24)
                }
            }
            .navigationBarHidden(true)
            .alert($store.scope(state: \.alert, action: \.alert))
            .fullScreenCover(item: $store.scope(state: \.auth, action: \.auth)) { store in
                NavigationStack {
                    AuthScreen(store: store)
                }
            }
            .disabled(store.isLoading)
            .animation(.default, value: store.isLoggedIn)
            .animation(.default, value: store.isLoadingUser)
            .onAppear {
                send(.onAppear)
            }
        }
    }
    
    // MARK: - Profile Section
    
    @ViewBuilder
    private func ProfileSection() -> some View {
        Section {
            ProfileButton()
        }
        .listRowBackground(Color(.Background.teritary))
    }
    
    // MARK: - Log In or Profile Button
    
    @ViewBuilder
    private func ProfileButton() -> some View {
        HStack(spacing: 0) { // Hacky HStack to enable tap animations
            Button {
                send(.profileButtonTapped)
            } label: {
                HStack(spacing: 0) {
                    ProfileAvatar()
                        .padding(.trailing, 12)
                        .redacted(if: store.isLoadingUser)

                    VStack(alignment: .leading, spacing: 4) {
                        ProfileTitle()
                        ProfileDescription()
                    }
                    .redacted(if: store.isLoadingUser)
                    
                    Spacer(minLength: 8)
                    
                    Image(systemSymbol: .chevronRight)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color(.Labels.quintuple))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        .frame(minHeight: 88)
    }
    
    // MARK: - ProfileAvatar
    
    @ViewBuilder
    private func ProfileAvatar() -> some View {
        if store.isLoggedIn, let user = store.user {
            LazyImage(url: user.imageUrl) { state in
                Group {
                    if let image = state.image {
                        image.resizable().scaledToFill()
                    } else {
                        Color(.systemBackground)
                    }
                }
                .skeleton(with: state.isLoading, shape: .circle)
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())
        } else {
            Circle()
                .fill(Color(.Background.quaternary))
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemSymbol: .personCropCircle)
                        .resizable()
                        .frame(width: 22, height: 22)
                        .foregroundStyle(tintColor)
                }
        }
    }
    
    // MARK: - ProfileTitle
    
    @ViewBuilder
    private func ProfileTitle() -> some View {
        Group {
            if store.isLoggedIn, let user = store.user {
                Text(user.nickname)
            } else {
                Text("Log in...", bundle: .module)
            }
        }
        .font(.title2.bold())
        .foregroundStyle(Color(.Labels.primary))
    }
    
    // MARK: - ProfileDescription
    
    @ViewBuilder
    private func ProfileDescription() -> some View {
        Group {
            if store.isLoggedIn {
                Text("Your profile", bundle: .module)
            } else {
                Text("Into your profile", bundle: .module)
            }
        }
        .font(.footnote)
        .foregroundStyle(tintColor)
    }
    
    // MARK: - Navigation Section
    
     @ViewBuilder
     private func NavigationSection() -> some View {
         Section {
             if store.isLoggedIn {
//                 Row(symbol: .docTextImage, title: "Articles") {
//                     send(.articlesButtonTapped)
//                 }
//                 
//                 Row(symbol: .starBubble, title: "Favorites") {
//                     send(.favoritesButtonTapped)
//                 }
//                 
//                 Row(symbol: .bubbleLeftAndBubbleRight, title: "Forum") {
//                     send(.forumButtonTapped)
//                 }
                 
                 Row(symbol: .person2, title: "QMS", badgeCount: store.qmsBadgeCount) {
                     send(.qmsButtonTapped)
                 }
                 
                 Row(symbol: .at, title: "Mentions", badgeCount: store.mentionsBadgeCount) {
                     send(.mentionsButtonTapped)
                 }
                 
                 Row(symbol: .clockArrowCirclepath, title: "History") {
                     send(.historyButtonTapped)
                 }
                 
                 Row(symbol: ._smartphone, title: "DevDB") {
                     send(.devDBButtonTapped)
                 }
                 
                 if store.isTicketsAvailable {
                     Row(symbol: .exclamationmarkBubble, title: "Tickets") {
                         send(.ticketsButtonTapped)
                     }
                 }
             }
         }
         .listRowBackground(Color(.Background.teritary))
     }
    
    // MARK: - Settings Section
    
    @ViewBuilder
    private func SettingsSection() -> some View {
        Section {
            Row(symbol: .gearshape, title: "Settings") {
                send(.settingsButtonTapped)
            }
        }
        .listRowBackground(Color(.Background.teritary))
    }
    
    // MARK: - Links Section
    
    @ViewBuilder
    private func LinksSection() -> some View {
        Section {
            Row(symbol: .boltHeart, title: "Support on Boosty", isBold: true) {
                send(.supportOnBoostyButtonTapped)
            }
            
            Row(symbol: .paperplane, title: "Chat in Telegram") {
                send(.telegramChatButtonTapped)
            }
            
            Row(symbol: .infoBubble, title: "Topic on 4PDA") {
                send(.appDiscussionButtonTapped)
            }
            
            Row(symbol: .folderBadgeGearshape, title: "GitHub repository") {
                send(.githubButtonTapped)
            }
        }
        .listRowBackground(Color(.Background.teritary))
    }
    
    // MARK: - Logout Section
    
    @ViewBuilder
    private func LogoutSection() -> some View {
        Section {
            if store.isLoggedIn {
                Row(symbol: .iphoneAndArrowForward, title: "Logout", hideChevron: true) {
                    send(.logoutButtonTapped)
                }
            }
        }
        .listRowBackground(Color(.Background.teritary))
    }
    
    // MARK: - Row
    
    @ViewBuilder
    private func Row(
        symbol: SFSymbol,
        title: LocalizedStringKey,
        isBold: Bool = false,
        badgeCount: Int = 0,
        hideChevron: Bool = false,
        action: @escaping () -> Void = {}
    ) -> some View {
        HStack(spacing: 0) { // Hacky HStack to enable tap animations
            Button {
                action()
            } label: {
                HStack(spacing: 0) {
                    Image(systemSymbol: symbol)
                        .font(.title2)
                        .foregroundStyle(tintColor)
                        .frame(width: 36)
                        .padding(.trailing, 12)
                    
                    Text(title, bundle: .module)
                        .font(.body)
                        .foregroundStyle(Color(.Labels.primary))
                        .bold(isBold)
                    
                    Spacer(minLength: 8)
                    
                    if badgeCount > 0 {
                        EmptyView()
                            .badge(badgeCount)
                            ._badgeProminence(.increased)
                    } else if !hideChevron {
                        Image(systemSymbol: .chevronRight)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color(.Labels.quintuple))
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        .frame(minHeight: 60)
    }
}

extension SFSymbol {
    static var _smartphone: SFSymbol {
        if #available(iOS 17, *) {
            return .smartphone
        } else {
            return .phone
        }
    }
}

// MARK: - Previews

#Preview(#"Logged Out "More""#) {
    NavigationStack {
        MoreScreen(
            store: Store(
                initialState: MoreFeature.State()
            ) {
                MoreFeature()
            }
        )
    }
    .environment(\.tintColor, Color(.Theme.primary))
    .onAppear {
        @Shared(.userSession) var userSession: UserSession?
        $userSession.withLock { $0 = nil }
    }
}

@available(iOS 17, *)
#Preview(#"Logged In "More""#) {
    @Previewable @State var store = Store(
        initialState: MoreFeature.State()
    ) {
        MoreFeature()
    } withDependencies: {
        $0.apiClient.getUnread = { _ in
            return .mockBadges
        }
    }
    
    return NavigationStack {
        MoreScreen(store: store)
    }
    .environment(\.tintColor, Color(.Theme.primary))
    .onAppear {
        @Shared(.userSession) var userSession: UserSession?
        $userSession.withLock { $0 = .mock }
    }
}
