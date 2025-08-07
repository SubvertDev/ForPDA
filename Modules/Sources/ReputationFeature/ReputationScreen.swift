//
//  ReputationScreen.swift
//  ForPDA
//
//  Created by Рустам Ойтов on 11.07.2025.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import SharedUI
import Models

@ViewAction(for: ReputationFeature.self)
public struct ReputationScreen: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<ReputationFeature>
    @Environment(\.tintColor) private var tintColor
    
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
                    if !store.isLoading {
                        switch store.pickerSelection {
                        case .history:
                            ReputationSelection(isHistory: true)
                                .onAppear {
                                    send(.onAppear)
                                }
                            
                        case .votes:
                            ReputationSelection(isHistory: false)
                                .onAppear {
                                    send(.onAppear)
                                }
                        }
                    } else {
                        Spacer()
                        PDALoader()
                            .frame(width: 24, height: 24)
                        Spacer()
                    }
                }
            }
            .navigationTitle(Text("Reputation", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - ReputationSelection
    
    @ViewBuilder
    private func ReputationSelection(isHistory: Bool) -> some View {
        ZStack {
            Color(.Background.primary)
                .ignoresSafeArea()
            
            if let votes = store.historyData?.votes, !votes.isEmpty {
                List {
                    ForEach(votes, id: \.self) { vote in
                        ReputationCell(vote: vote)
                            .onAppear {
                                if let index = votes.firstIndex(of: vote),
                                   index == votes.count - 2 {
                                    send(.loadMore)
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    send(.refresh(isHistory))
                }
            } else {
                Spacer()
                EmptyReputation(isHistory: isHistory)
                Spacer()
            }
        }
    }
    
    // MARK: - SegmentPicker
    
    @ViewBuilder
    private func SegmentPicker() -> some View {
        _Picker("", selection: $store.pickerSelection) {
            Text("History", bundle: .module)
                .tag(ReputationFeature.PickerSelection.history)
            Text("My votes", bundle: .module)
                .tag(ReputationFeature.PickerSelection.votes)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 18)
    }
    
    // MARK: - ReputationCell
    
    @ViewBuilder
    private func ReputationCell(vote: ReputationVote) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Button {
                    send(.profileTapped(vote.authorId))
                } label: {
                    Text(vote.authorName)
                        .foregroundStyle(Color(.Labels.primary))
                        .font(.system(size: 16, weight: .semibold))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(LocalizedStringKey(vote.markLabel), bundle: .module)
                    .foregroundStyle(vote.flag == 1 ? tintColor : Color(.Labels.teritary))
                    .font(.system(size: 12, weight: .medium))
                
                Image(systemSymbol: vote.arrowSymbol)
                    .resizable()
                    .foregroundStyle(vote.flag == 1 ? tintColor : Color(.Labels.teritary))
                    .frame(maxWidth: 20, maxHeight: 20)
            }
            .padding(.horizontal, 12)
            
            HStack {
                Image(systemSymbol: vote.systemSymbol)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color(.Labels.teritary))
                    .frame(width: 20, height: 16)
                
                Button {
                    send(.sourceTapped(vote.titleId, vote.title, vote.createdInType))
                } label: {
                    Text(vote.title)
                        .lineLimit(1)
                        .foregroundStyle(Color(.Labels.teritary))
                        .font(.system(size: 12, weight: .regular))
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            
            Text(vote.reason)
                .lineLimit(1)
                .foregroundStyle(Color(.Labels.primary))
                .font(.system(size: 15, weight: .regular))
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            
            HStack {
                Text(formatDate(vote.createdAt))
                    .foregroundStyle(Color(.Labels.teritary))
                    .font(.system(size: 12, weight: .regular))
                
                Spacer()
                
                Menu {
                    MenuButtons(id: vote.authorId)
                } label: {
                    Image(systemSymbol: .ellipsis)
                        .foregroundStyle(Color(.Labels.teritary))
                }
                .menuStyle(.button)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
        }
        .contentShape(Rectangle())
        .contextMenu {
            MenuButtons(id: vote.authorId)
        }
    }
    //MARK: - Empty View
    
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
                .foregroundColor(Color(.Labels.primary))
                .padding(.bottom, 6)
            
            Text(isHistory ? "Write topics on the forum and get reputation from other users" : "Vote for other users if you liked the topic on the forum", bundle: .module)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(.Labels.teritary))
                .frame(maxWidth: UIScreen.main.bounds.width * 0.7)
                .padding(.horizontal, 55)
        }
    }
    
    // MARK: - MenuButtons
    
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
    
    // MARK: - formatDate
    
    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMMM yyyy HH:mm"
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
            }
        )
        .environment(\.locale, Locale(identifier: "ru"))
    }
}
