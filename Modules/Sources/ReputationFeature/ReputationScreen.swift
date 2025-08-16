//
//  ReputationScreen.swift
//  ForPDA
//
//  Created by Рустам Ойтов on 11.07.2025.
//

import SwiftUI
import ComposableArchitecture
import SharedUI
import Models

@ViewAction(for: ReputationFeature.self)
public struct ReputationScreen: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<ReputationFeature>
    @Environment(\.tintColor) private var tintColor
    
    // MARK: - init
    
    public init(store: StoreOf<ReputationFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                VStack {
                    SegmentPicker()
                    
                    if store.isLoading {
                        Spacer()
                        PDALoader()
                            .frame(width: 24, height: 24)
                        Spacer()
                    } else {
                        ReputationSection()
                    }
                }
            }
            .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
            .navigationTitle(Text("Reputation", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                send(.onAppear)
            }
        }
    }
    
    // MARK: - Reputation Section
    
    @ViewBuilder
    private func ReputationSection() -> some View {
        ZStack {
            Color(.Background.primary)
                .ignoresSafeArea()
            
            if store.historyData.isEmpty {
                Spacer()
                EmptyReputation(isHistory: store.pickerSection == .history)
                Spacer()
            } else {
                List(store.historyData, id: \.self) { vote in
                    ReputationRow(vote: vote)
                        .listRowBackground(Color(.Background.primary))
                        .onAppear {
                            if let index = store.historyData.firstIndex(of: vote),
                               index == store.historyData.count - 5 {
                                send(.loadMore)
                            }
                        }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color(.Background.primary))
                .refreshable {
                    await send(.refresh).finish()
                }
            }
        }
    }
    
    // MARK: - Segment Picker
    
    @ViewBuilder
    private func SegmentPicker() -> some View {
        _Picker("", selection: $store.pickerSection) {
            Text("History", bundle: .module)
                .tag(ReputationFeature.PickerSection.history)
            Text("My votes", bundle: .module)
                .tag(ReputationFeature.PickerSection.votes)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 18)
    }
    
    // MARK: - Reputation Row
    
    @ViewBuilder
    private func ReputationRow(vote: ReputationVote) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button {
                    send(.profileTapped(vote.authorId))
                } label: {
                    Text(vote.authorName)
                        .foregroundStyle(Color(.Labels.primary))
                        .font(.callout)
                        .bold()
                        .fontWeight(.semibold)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(LocalizedStringKey(vote.markLabel), bundle: .module)
                    .foregroundStyle(vote.flag == 1 ? tintColor : Color(.Labels.teritary))
                    .font(.caption)
                    .fontWeight(.medium)
                
                Image(systemSymbol: vote.arrowSymbol)
                    .foregroundStyle(vote.flag == 1 ? tintColor : Color(.Labels.teritary))
                    .font(.body)
            }
            
            HStack(spacing: 0) {
                Image(systemSymbol: vote.systemSymbol)
                    .foregroundStyle(Color(.Labels.teritary))
                    .font(.caption)
                    .padding(.trailing, 6)
                
                Button {
                    send(.sourceTapped(vote))
                } label: {
                    Text(vote.title)
                        .lineLimit(1)
                        .foregroundStyle(Color(.Labels.teritary))
                        .font(.caption)
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding(.top, 4)
            
            Text(vote.reason)
                .foregroundStyle(Color(.Labels.primary))
                .font(.subheadline)
                .multilineTextAlignment(.leading)
                .padding(.vertical, 8)
            
            HStack {
                Text(formatDate(vote.createdAt))
                    .foregroundStyle(Color(.Labels.teritary))
                    .font(.caption)
                
                Spacer()
                
                Menu {
                    MenuButtons(id: vote.authorId)
                } label: {
                    Image(systemSymbol: .ellipsis)
                        .foregroundStyle(Color(.Labels.teritary))
                        .font(.body)
                }
                .menuStyle(.button)
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, 12)
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
        .contentShape(Rectangle())
        .background(Color(.Background.primary))
        .contextMenu {
            MenuButtons(id: vote.authorId)
        }
    }
    // MARK: - Empty Reputation
    
    @ViewBuilder
    private func EmptyReputation(isHistory: Bool) -> some View {
        VStack(spacing: 0) {
            Image(systemSymbol: .plusminus)
                .font(.title)
                .foregroundStyle(tintColor)
                .frame(width: 48, height: 48)
                .padding(.bottom, 8)
            
            Text("No reputation history", bundle: .module)
                .font(.title3)
                .bold()
                .foregroundStyle(Color(.Labels.primary))
                .padding(.bottom, 6)
            
            Text(isHistory ? "Write topics on the forum and get reputation from other users" : "Vote for other users if you liked the topic on the forum", bundle: .module)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(.Labels.teritary))
                .frame(maxWidth: UIScreen.main.bounds.width * 0.7)
                .padding(.horizontal, 55)
        }
    }
    
    // MARK: - Menu Buttons
    
    @ViewBuilder
    private func MenuButtons(id: Int) -> some View {
        ContextButton(
            text: "Profile",
            symbol: .personCropCircle,
            bundle: .module,
            action: { send(.profileTapped(id)) }
        )
        
        ContextButton(
            text: "Complain",
            symbol: .exclamationmarkTriangle,
            bundle: .module,
            action: { print("Complain") }
        )
        .disabled(true)
    }
    
    // MARK: - format Date
    
    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMMM yyyy · HH:mm"
        return dateFormatter.string(from: date)
    }
}

// MARK: - Perception Picker
// https://github.com/pointfreeco/swift-perception/issues/100

struct _Picker<Label, SelectionValue, Content>: View
where Label: View, SelectionValue: Hashable, Content: View {
    let label: Label
    let content: Content
    let selection: Binding<SelectionValue>
    
    init(
        _ titleKey: String,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) where Label == Text {
        self.label = Text(titleKey)
        self.content = content()
        self.selection = selection
    }
    
    var body: some View {
        _PerceptionLocals.$skipPerceptionChecking.withValue(true) {
            Picker(selection: selection, content: { content }, label: { label })
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ReputationScreen(
            store: Store(
                initialState: ReputationFeature.State(userId: 0)
            ) {
                ReputationFeature()
            } withDependencies: {
                $0.apiClient.getReputationVotes = { _ in
                    try? await Task.sleep(for: .seconds(1))
                    return .mock
                }
            }
        )
    }
    .environment(\.tintColor, Color(.Theme.primary))
}

#Preview("Empty") {
    NavigationStack {
        ReputationScreen(
            store: Store(
                initialState: ReputationFeature.State(userId: 0)
            ) {
                ReputationFeature()
            } withDependencies: {
                $0.apiClient.getReputationVotes = { _ in
                    return ReputationVotes(votes: [], votesCount: 0)
                }
            }
        )
    }
    .environment(\.tintColor, Color(.Theme.primary))
}

