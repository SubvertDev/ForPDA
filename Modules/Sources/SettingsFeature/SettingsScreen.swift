//
//  SettingsScreen.swift
//
//
//  Created by Ilia Lubianoi on 12.05.2024.
//

import SwiftUI
import ComposableArchitecture
import SharedUI
import SFSafeSymbols
import Models

public struct SettingsScreen: View {
        
    @Perception.Bindable public var store: StoreOf<SettingsFeature>
    @Environment(\.tintColor) private var tintColor
    @Environment(\.colorScheme) private var colorScheme
    
    public init(store: StoreOf<SettingsFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                List {
                    ThemeSection()
                    BasicSection()
                    LinksSection()
                    AdvancedSection()
                    AboutAppSection()
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(Text("Settings", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
            .animation(.default, value: colorScheme)
        }
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private func Header(title: LocalizedStringKey) -> some View {
        Text(title, bundle: .module)
            .font(.subheadline)
            .bold()
            .foregroundStyle(Color(.Labels.teritary))
            .textCase(nil)
            .offset(x: -20)
            .padding(.bottom, 4)
    }
    
    // MARK: - Row
    
    enum RowType {
        case basic
        case toggle
        case navigation
        case backgroundPicker
        case themePicker
        case startPagePicker
    }
        
    @ViewBuilder
    private func Row(
        symbol: SFSymbol,
        title: LocalizedStringKey,
        type: RowType,
        isBold: Bool = false,
        toggle: Binding<Bool>? = nil,
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
                    
                    switch type {
                    case .basic:
                        EmptyView()
                        
                    case .toggle:
                        EmptyView()
                        
                    case .navigation:
                        Image(systemSymbol: .chevronRight)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color(.Labels.quintuple))
                        
                    case .backgroundPicker:
                        EnumPickerMenu(selection: $store.backgroundTheme) { theme in
                            HStack(spacing: 0) {
                                Text(theme.title, bundle: .module)
                                theme.image
                            }
                        } label: {
                            HStack(spacing: 9) {
                                Text(store.backgroundTheme.title, bundle: .module)
                                Image(systemSymbol: .chevronUpChevronDown)
                            }
                            .foregroundStyle(Color(.Labels.teritary))
                        }
                        
                    case .themePicker:
                        EnumPickerMenu(selection: $store.appTintColor) { tint in
                            HStack(spacing: 0) {
                                Text(tint.title, bundle: .module)
                                tint.image
                            }
                        } label: {
                            HStack(spacing: 9) {
                                Text(store.appTintColor.title, bundle: .module)
                                Image(systemSymbol: .chevronUpChevronDown)
                            }
                            .foregroundStyle(Color(.Labels.teritary))
                        }
                        
                    case .startPagePicker:
                        EnumPickerMenu(selection: $store.startPage) { tab in
                            Text(tab.title)
                        } label: {
                            HStack(spacing: 9) {
                                Text(store.startPage.title)
                                Image(systemSymbol: .chevronUpChevronDown)
                            }
                            .foregroundStyle(Color(.Labels.teritary))
                        }
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if let toggle {
                Toggle(String(""), isOn: toggle)
                    .labelsHidden()
            }
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        .frame(height: 60)
    }
    
    // MARK: - Theme Section
    
    @ViewBuilder
    private func ThemeSection() -> some View {
        Section {
            HStack(spacing: 29) {
                ForEach(AppColorScheme.allCases, id: \.self) { scheme in
                    WithPerceptionTracking {
                        SchemeButton(scheme: scheme)
                    }
                }
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        } header: {
            Header(title: "Theme")
        }
        // TODO: Wacky animation
        .background(
            Color(.Background.primary)
                .animation(.default, value: colorScheme)
        )
    }
    
    // MARK: - Scheme Button
    
    @ViewBuilder
    private func SchemeButton(scheme: AppColorScheme) -> some View {
        Button {
            store.send(.schemeButtonTapped(scheme), animation: .default)
        } label: {
            VStack(spacing: 0) {
                scheme.image
                    .aspectRatio(10/18, contentMode: .fit)
                    .padding(.bottom, 12)
                
                Text(scheme.title, bundle: .module)
                    .font(.body)
                    .foregroundStyle(Color(.Labels.primary))
                    .padding(.bottom, 10)
                
                if scheme == store.appColorScheme {
                    ZStack {
                        Circle()
                            .foregroundStyle(tintColor)
                        
                        Image(systemSymbol: .checkmark)
                            .font(.system(size: 13.5, weight: .semibold))
                            .foregroundStyle(Color(.Labels.primaryInvariably))
                            .frame(width: 22, height: 22)
                    }
                    .frame(width: 22, height: 22)
                } else {
                    Circle()
                        .strokeBorder(Color(.Labels.quintuple))
                        .frame(width: 22, height: 22)
                }
            }
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
    }
    
    // MARK: - Basic Section
    
    @ViewBuilder
    private func BasicSection() -> some View {
        Section {
            Row(symbol: ._1Circle, title: "Starting page", type: .startPagePicker)
            
            // Row(symbol: .paintpalette, title: "Background color", type: .backgroundPicker)
            
            // Row(symbol: .rectangleAndHandPointUpLeft, title: "Topic opening", type: .topicOpening)
            
            Row(symbol: .swatchpalette, title: "Accent color", type: .themePicker)
            
            Row(symbol: .rectangleAndHandPointUpLeft, title: "Navigation", type: .navigation) {
                store.send(.navigationButtonTapped)
            }
            
            Row(symbol: .bell, title: "Notifications", type: .navigation) {
                store.send(.notificationsButtonTapped)
            }
            
            Row(symbol: .globe, title: "Language", type: .navigation) {
                store.send(.languageButtonTapped)
            }
        } header: {
            Header(title: "Basic")
        }
        .listRowBackground(Color(.Background.teritary))
    }
    
    // MARK: - Advanced Section
    
    @ViewBuilder
    private func AdvancedSection() -> some View {
        Section {
            Row(symbol: .safari, title: "Safari extension", type: .navigation) {
                store.send(.safariExtensionButtonTapped)
            }
            
            Row(symbol: .docOnDoc, title: "Copy Debug ID", type: .navigation) {
                store.send(.copyDebugIdButtonTapped)
            }
            
            Row(symbol: .trash, title: "Clear cache", type: .navigation) {
                store.send(.clearCacheButtonTapped)
            }
        } header: {
            Header(title: "Advanced")
                .onTapGesture {
                    #if DEBUG
                    store.send(.onDeveloperMenuTapped)
                    #endif
                }
        }
        .listRowBackground(Color(.Background.teritary))
    }
    
    // MARK: - Advanced Section
    
    @ViewBuilder
    private func LinksSection() -> some View {
        Section {
            Row(symbol: .boltHeart, title: "Support on Boosty", type: .navigation, isBold: true) {
                store.send(.supportOnBoostyButtonTapped)
            }
            
            Row(symbol: .paperplane, title: "App discussion in Telegram", type: .navigation) {
                store.send(.telegramChatButtonTapped)
            }
            
            Row(symbol: .paperplane, title: "List of changes in Telegram", type: .navigation) {
                store.send(.telegramChangelogButtonTapped)
            }
            
            Row(symbol: .infoBubble, title: "App discussion on the forum", type: .navigation) {
                store.send(.appDiscussionButtonTapped)
            }
            
            Row(symbol: .folderBadgeGearshape, title: "GitHub repository", type: .navigation) {
                store.send(.githubButtonTapped)
            }
        } header: {
            Header(title: "Links")
        }
        .listRowBackground(Color(.Background.teritary))
    }
    
    // MARK: - About App Section
    
    @ViewBuilder
    private func AboutAppSection() -> some View {
        Section {
            Row(symbol: .infoBubble, title: "Version \(store.appVersionAndBuild) [\(store.releaseChannel)]", type: .basic) {}
            
            Row(symbol: .folderBadgeGearshape, title: "Check new versions on GitHub", type: .navigation) {
                store.send(.checkVersionsButtonTapped)
            }
        } header: {
            Header(title: "About app")
        }
        .listRowBackground(Color(.Background.teritary))
    }
}

// MARK: - Extensions

extension AppColorScheme {
    var title: LocalizedStringKey {
        switch self {
        case .light:    "Light"
        case .dark:     "Dark.Scheme"
        case .system:   "System"
        }
    }
    
    var image: Image {
        switch self {
        case .light:
            Image(.Settings.lightThemeExample).resizable()
        case .dark:
            Image(.Settings.darkThemeExample).resizable()
        case .system:
            Image(.Settings.systemThemeExample).resizable()
        }
    }
}

extension BackgroundTheme {
    var title: LocalizedStringKey {
        switch self {
        case .blue: return "Blue"
        case .dark: return "Dark.Theme"
        }
    }
    
    var image: Image {
        switch self {
        case .blue: Image(.Settings.circleBlue)
        case .dark: Image(.Settings.circleDark)
        }
    }
}

extension AppTintColor {
    var title: LocalizedStringKey {
        switch self {
        case .lettuce:  "Lettuce"
        case .orange:   "Orange"
        case .pink:     "Pink"
        case .primary:  "Primary"
        case .purple:   "Purple"
        case .scarlet:  "Scarlet"
        case .sky:      "Sky"
        case .yellow:   "Yellow"
        }
    }
    
    var image: Image {
        switch self {
        case .lettuce:  Image(.Settings.Theme.circleLettuce)
        case .orange:   Image(.Settings.Theme.circleOrange)
        case .pink:     Image(.Settings.Theme.circlePink)
        case .primary:  Image(.Settings.Theme.circlePrimary)
        case .purple:   Image(.Settings.Theme.circlePurple)
        case .scarlet:  Image(.Settings.Theme.circleScarlet)
        case .sky:      Image(.Settings.Theme.circleSky)
        case .yellow:   Image(.Settings.Theme.circleYellow)
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        SettingsScreen(
            store: Store(
                initialState: SettingsFeature.State()
            ) {
                SettingsFeature()
            }
        )
    }
    .environment(\.tintColor, Color(.Theme.primary))
}
