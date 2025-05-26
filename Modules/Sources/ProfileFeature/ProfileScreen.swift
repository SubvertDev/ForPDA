//
//  ProfileScreen.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 02.08.2024.
//

import SwiftUI
import ComposableArchitecture
import SkeletonUI
import NukeUI
import SharedUI
import SFSafeSymbols
import Models
import RichTextKit
import ParsingClient

@ViewAction(for: ProfileFeature.self)
public struct ProfileScreen: View {
    
    public enum PickerSelection {
        case general
        case statistics
        case achievements
    }
    
    public let store: StoreOf<ProfileFeature>
    @Environment(\.tintColor) private var tintColor
    @State private var pickerSelection: PickerSelection = .general
    
    public init(store: StoreOf<ProfileFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                if let user = store.user {
                    List {
                        Header(user: user)
                        NavigationSection()
                        SegmentPicker()
                        
                        switch pickerSelection {
                        case .general:
                            GeneralSegment(user: user)
                            
                        case .statistics:
                            StatisticsSegment(user: user)
                            
                        case .achievements:
                            AchievementsSegment(user: user)
                        }
                    }
                    .listSectionSpacingBackport(28)
                    .scrollContentBackground(.hidden)
                } else {
                    PDALoader()
                        .frame(width: 24, height: 24)
                }
            }
            .navigationTitle(Text("Profile", bundle: .module))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    ToolbarButtons()
                }
            }
            .task {
                send(.onAppear)
            }
        }
    }
    
    // MARK: - Toolbar Items
    
    @ViewBuilder
    private func ToolbarButtons() -> some View {
        if store.shouldShowToolbarButtons {
            Button {
                send(.settingsButtonTapped)
            } label: {
                Image(systemSymbol: .gearshape)
            }
            
            Button {
                send(.logoutButtonTapped)
            } label: {
                Image(systemSymbol: .rectanglePortraitAndArrowForward)
            }
        }
    }
    
    // MARK: - Profile Header
    
    @ViewBuilder
    private func Header(user: User) -> some View {
        VStack(alignment: .center, spacing: 0) {
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
            .frame(width: 128, height: 128)
            .clipShape(Circle())
            .padding(.bottom, 10)
            
            Text(user.nickname)
                .font(.headline)
                .foregroundStyle(Color(.Labels.primary))
                .padding(.bottom, 4)
            
            if !user.lastSeenDate.isOnlineHidden() {
                Text(user.lastSeenDate.formattedOnlineDate(), bundle: .module)
                    .font(.footnote)
                    .foregroundStyle(user.lastSeenDate.isUserOnline() ? Color(.Main.green) : Color(.Labels.teritary))
                    .padding(.bottom, 8)
            }
            
            if let signature = user.signatureAttributed {
                RichText(text: signature, onUrlTap: { url in
                    send(.deeplinkTapped(url, .signature))
                }) {
                    ($0 as? UITextView)?.backgroundColor = .clear
                    ($0 as? UITextView)?.textAlignment = .center
                    ($0 as? UITextView)?.isEditable = false
                    ($0 as? UITextView)?.isScrollEnabled = false
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(
                    Color(.Background.teritary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                )
            }
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
    
    // MARK: - Navigation Section
    
    @ViewBuilder
    private func NavigationSection() -> some View {
        if store.shouldShowToolbarButtons {
            Section {
                Row(symbol: .person2, title: "QMS", type: .navigation) {
                    send(.qmsButtonTapped)
                }
                
                Section {
                    Row(symbol: .clockArrowCirclepath, title: "History", type: .navigation) {
                        send(.historyButtonTapped)
                    }
                }
            }
            .listRowBackground(Color(.Background.teritary))
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
    }
    
    // MARK: - Segment Picker
    
    @ViewBuilder
    private func SegmentPicker() -> some View {
        Picker(String(""), selection: $pickerSelection) {
            Text("General", bundle: .module)
                .tag(PickerSelection.general)
            Text("Statistics", bundle: .module)
                .tag(PickerSelection.statistics)
            
            if !store.user!.achievements.isEmpty {
                Text("Achievements", bundle: .module)
                    .tag(PickerSelection.achievements)
            }
        }
        .pickerStyle(.segmented)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowBackground(Color.clear)
    }
    
    // MARK: - General Segment
    
    @ViewBuilder
    private func GeneralSegment(user: User) -> some View {
        GroupsSection(user: user)
        PersonalSection(user: user)
        if user.aboutMe != nil {
            AboutSection(user: user)
        }
        if !user.devDBdevices.isEmpty {
            DevicesSection(devices: user.devDBdevices)
        }
    }
    
    // MARK: - Groups Section
    @ViewBuilder
    private func GroupsSection(user: User) -> some View {
        Section {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    VStack(spacing: 2) {
                        Text("Group", bundle: .module)
                            .font(.footnote)
                            .foregroundStyle(Color(.Labels.teritary))
                        Text(user.group.title)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color(dynamicTuple: user.group.hexColor))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(12)
                    .background(
                        Color(.Background.teritary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    )
                    
                    if let status = user.statusAttributed {
                        VStack(spacing: 2) {
                            Text("Status", bundle: .module)
                                .font(.footnote)
                                .foregroundStyle(Color(.Labels.teritary))
                            
                            RichText(text: status, configuration: {
                                ($0 as? UITextView)?.backgroundColor = .clear
                                ($0 as? UITextView)?.textAlignment = .center
                                ($0 as? UITextView)?.isEditable = false
                                ($0 as? UITextView)?.isScrollEnabled = false
                            })
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(12)
                        .background(
                            Color(.Background.teritary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        )
                    }
                }
                
                HStack {
                    Text("Registration date", bundle: .module)
                        .font(.body)
                        .foregroundStyle(Color(.Labels.primary))
                    
                    Spacer()
                    
                    Text(user.registrationDate.formatted(date: .numeric, time: .omitted))
                        .font(.body)
                        .foregroundStyle(Color(.Labels.teritary))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 19)
                .background(
                    Color(.Background.teritary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                )
            }
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowBackground(Color.clear)
    }
    
    // MARK: - Personal Section
    
    @ViewBuilder
    private func PersonalSection(user: User) -> some View {
        Section {
            if let email = user.email {
                Row(title: "Email", type: .description(email))
            }
            if let birthdate = user.birthdate {
                // TODO: Format
                Row(title: "Birthdate", type: .description(birthdate))
            }
            if let gender = user.gender, gender != .unknown {
                Row(title: "Gender", type: .description(gender.title))
            }
            if let city = user.city {
                Row(title: "City", type: .description(city))
            }
            if let userTime = user.userTimeFormatted {
                // TODO: Format
                Row(title: "User time", type: .description(String(userTime)))
            }
        } header: {
            SectionHeader(title: "Personal info")
        }
        .listRowBackground(Color(.Background.teritary))
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
    
    // MARK: - About Section
    
    @ViewBuilder
    private func AboutSection(user: User) -> some View {
        Section {
            if let aboutMe = user.aboutMeAttributed {
                RichText(text: aboutMe, onUrlTap: { url in
                    send(.deeplinkTapped(url, .about))
                })
                .font(.body)
                .foregroundStyle(Color(.Labels.primary))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } header: {
            SectionHeader(title: "About me")
        }
        .listRowBackground(Color(.Background.teritary))
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
    
    // MARK: - Devices Section
    
    @ViewBuilder
    private func DevicesSection(devices: [User.Device]) -> some View {
        Section {
            ForEach(devices) { device in
                HStack(spacing: 0) {
                    Text(device.name)
                        .font(.body)
                        .foregroundStyle(Color(.Labels.primary))
                    
                    Spacer(minLength: 8)
                    
                    if device.main {
                        Circle()
                            .font(.title2)
                            .foregroundStyle(tintColor)
                            .frame(width: 8)
                            .padding(.trailing, 12)
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .buttonStyle(.plain)
                .frame(height: 60)
            }
        } header: {
            SectionHeader(title: "Devices List")
        }
        .listRowBackground(Color(.Background.teritary))
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
    
    // MARK: - Statistics Segment
    
    @ViewBuilder
    private func StatisticsSegment(user: User) -> some View {
        SiteStatisticsSection(user: user)
        ForumStatisticsSection(user: user)
    }
    
    // MARK: - Site Statistics Section
    
    @ViewBuilder
    private func SiteStatisticsSection(user: User) -> some View {
        Section {
            Row(title: "Karma", type: .description(String(user.karma)))
            Row(title: "Posts", type: .description(String(user.posts)))
            Row(title: "Comments", type: .description(String(user.comments)))
        } header: {
            SectionHeader(title: "Site statistics")
        }
        .listRowBackground(Color(.Background.teritary))
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
    
    // MARK: - Forum Statistics Section
    
    @ViewBuilder
    private func ForumStatisticsSection(user: User) -> some View {
        Section {
            Row(title: "Reputation", type: .description(String(user.reputation)))
            Row(title: "Topics", type: .description(String(user.topics)))
            Row(title: "Replies", type: .description(String(user.replies)))
        } header: {
            SectionHeader(title: "Forum statistics")
        }
        .listRowBackground(Color(.Background.teritary))
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
    
    // MARK: - Achievements Segment
    
    @ViewBuilder
    private func AchievementsSegment(user: User) -> some View {
        ForEach(user.achievements) { achievement in
            AchievementsSection(achievement: achievement)
        }
    }
    
    @ViewBuilder
    private func AchievementsSection(achievement: User.Achievement) -> some View {
        Section {
            Button {
                send(.deeplinkTapped(achievement.forumUrl, .achievement))
            } label: {
                HStack(spacing: 0) {
                    HStack {
                        LazyImage(url: achievement.imageUrl) { state in
                            Group {
                                if let image = state.image {
                                    image.resizable().scaledToFill()
                                } else {
                                    Color(.Background.teritary)
                                }
                            }
                            .skeleton(with: state.isLoading, shape: .circle)
                        }
                        .frame(width: UIScreen.main.bounds.width / 5,
                               height: UIScreen.main.bounds.width / 5)
                        .padding(.trailing, 12)
                        .overlay(alignment: .bottomTrailing) {
                            if achievement.count > 1 {
                                Text(String("\(achievement.count)"))
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(tintColor)
                                    .clipShape(Circle())
                            }
                        }
                    }
                    
                    VStack(spacing: 8) {
                        Text(achievement.name)
                            .font(.headline)
                            .foregroundStyle(Color(.Labels.secondary))
                        
                        if !achievement.description.isEmpty {
                            Text(achievement.description)
                                .font(.footnote)
                                .foregroundStyle(Color(.Labels.teritary))
                        }
                        
                        Text(achievement.presentationDate.formatted(date: .numeric, time: .omitted))
                            .font(.footnote)
                            .foregroundStyle(Color(.Labels.teritary))
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    Color(.Background.teritary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                )
            }
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowBackground(Color.clear)
    }
    
    // MARK: - Section Header
    
    @ViewBuilder
    private func SectionHeader(title: LocalizedStringKey) -> some View {
        Text(title, bundle: .module)
            .font(.subheadline)
            .foregroundStyle(Color(.Labels.teritary))
            .textCase(nil)
            .offset(x: 16)
            .padding(.bottom, 4)
    }
    
    // MARK: - Row
    
    enum RowType {
        case basic
        case description(String)
        case navigation
    }
    
    @ViewBuilder
    private func Row(symbol: SFSymbol? = nil, title: LocalizedStringKey, type: RowType, action: @escaping () -> Void = {}) -> some View {
        HStack(spacing: 0) { // Hacky HStack to enable tap animations
            Button {
                action()
            } label: {
                HStack(spacing: 0) {
                    if let symbol {
                        Image(systemSymbol: symbol)
                            .font(.title2)
                            .foregroundStyle(tintColor)
                            .frame(width: 36)
                            .padding(.trailing, 12)
                    }
                    
                    Text(title, bundle: .module)
                        .font(.body)
                        .foregroundStyle(Color(.Labels.primary))
                    
                    Spacer(minLength: 8)
                    
                    switch type {
                    case .basic:
                        EmptyView()
                        
                    case let .description(text):
                        Text(text)
                            .font(.body)
                            .foregroundStyle(Color(.Labels.teritary))
                        
                    case .navigation:
                        Image(systemSymbol: .chevronRight)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color(.Labels.quintuple))
                    }
                }
                .contentShape(Rectangle())
            }
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        .buttonStyle(.plain)
        .frame(height: 60)
    }
    
    @ViewBuilder
    private func informationRow(title: LocalizedStringKey, description: String) -> some View {
        HStack {
            Text(title, bundle: .module)
            
            Spacer()
            
            Text(description)
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private func informationRow(title: LocalizedStringKey, description: LocalizedStringKey) -> some View {
        HStack {
            Text(title, bundle: .module)
            
            Spacer()
            
            Text(description, bundle: .module)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Extensions

private extension Date {
    
    func isOnlineHidden() -> Bool {
        return timeIntervalSince1970 == 0
    }
    
    func isUserOnline() -> Bool {
        return Date().timeIntervalSince1970 - timeIntervalSince1970 < 900
    }
    
    func formattedOnlineDate() -> LocalizedStringKey {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let formattedTime = formatter.string(from: self)

        if isUserOnline() {
            return LocalizedStringKey("Online")
        } else if Calendar.current.isDateInToday(self) {
            return LocalizedStringKey("Last seen at \(formattedTime)")
        } else if Calendar.current.isDateInYesterday(self) {
            return LocalizedStringKey("Last seen yesterday at \(formattedTime)")
        }
        
        formatter.dateFormat = "dd.MM.yy, HH:mm"
        return LocalizedStringKey("Last seen \(formatter.string(from: self))")
    }
}

private extension View {
    func listSectionSpacingBackport(_ value: CGFloat) -> some View {
        self.modifier(ListSectionSpacing(value: value))
    }
}

private struct ListSectionSpacing: ViewModifier {
    
    var value: CGFloat
    
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .listSectionSpacing(value)
        } else {
            content
        }
    }
}

extension User {
    var signatureAttributed: NSAttributedString? {
        return BBCodeParser.parse(signature, fontStyle: .footnote)
    }
    
    var statusAttributed: NSAttributedString? {
        if let status {
            let trimmed = status.trimmingCharacters(in: .whitespacesAndNewlines)
            return !trimmed.isEmpty ? BBCodeParser.parse(status) : nil
        }
        return nil
    }
    
    var aboutMeAttributed: NSAttributedString? {
        return BBCodeParser.parse(aboutMe, fontStyle: .body)
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        ProfileScreen(
            store: Store(
                initialState: ProfileFeature.State(
                    userId: 3640948
                )
            ) {
                ProfileFeature()
            } withDependencies: {
                $0.apiClient = .previewValue
                $0.apiClient.getUser = { @Sendable _, _ in
                    return AsyncThrowingStream { continuation in
                        Task {
                            continuation.yield(User.mock)
                            try? await Task.sleep(for: .seconds(0.1))
                            continuation.yield(User.mock)
                        }
                    }
                }
            }
        )
    }
    .environment(\.tintColor, Color(.Theme.primary))
}
