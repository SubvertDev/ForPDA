//
//  ForumMergeView.swift
//  ForPDA
//
//  Created by Xialtal on 30.09.26.
//

import SwiftUI
import ComposableArchitecture
import Models
import SharedUI

@ViewAction(for: ForumMergeFeature.self)
public struct ForumMergeView: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<ForumMergeFeature>
    @Environment(\.tintColor) private var tintColor
    
    // MARK: - Init
    
    public init(store: StoreOf<ForumMergeFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            List {
                switch store.type {
                case .topics(let topics):
                    MergeTopics(topics)
                    
                case .posts:
                    EmptyView()
                }
            }
            ._listSectionSpacing(28)
            .scrollContentBackground(.hidden)
            ._toolbarTitleDisplayMode(.inline)
            .navigationTitle(Text("Merger", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                       send(.closeButtonTapped)
                    } label: {
                        if isLiquidGlass {
                            Image(systemSymbol: .xmark)
                        } else {
                            Image(systemSymbol: .xmark)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(Color(.Labels.teritary))
                                .frame(width: 30, height: 30)
                                .background(
                                    Circle()
                                        .fill(Color(.Background.quaternary))
                                        .clipShape(Circle())
                                )
                        }
                    }
                }
            }
            ._safeAreaBar(edge: .bottom) {
                MergeButton()
            }
            .background(Color(.Background.primary))
            .onAppear {
                send(.onAppear)
            }
        }
    }
    
    // MARK: - Merge Topics
    
    @ViewBuilder
    private func MergeTopics(_ topics: [TopicInfo]) -> some View {
        Section {
            Menu {
                Picker(selection: $store.targetTopicId, label: EmptyView()) {
                    ForEach(topics, id: \.id) { topic in
                        Text(verbatim: topic.name)
                            .tag(topic.id)
                    }
                }
            } label: {
                PickerHeader(
                    title: topics.first(where: { $0.id == store.targetTopicId })?.name ?? "-/-"
                )
            }
        } header: {
            Header(title: "Target Topic")
        }
        .listSectionSeparator(.hidden)
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowBackground(Color(.Background.primary))
        
        Section {
            ForEach(Array(topics.enumerated()), id: \.element) { index, topic in
                TopicRow(topics.count, index, topic)
            }
        } header: {
            Header(title: "Selected Topics")
        }
        .listSectionSeparator(.hidden)
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
    
    // MARK: - Topic Row
    
    private func TopicRow(_ allCount: Int, _ index: Int, _ topic: TopicInfo) -> some View {
        WithPerceptionTracking {
            VStack(spacing: 0) {
                let radius: CGFloat = isLiquidGlass ? 24 : 10
                SharedUI.TopicRow(
                    title: .plain(topic.name),
                    date: topic.lastPost.date,
                    username: topic.lastPost.username,
                    isClosed: topic.isClosed,
                    isUnread: false,
                    onAction: { _ in }
                )
                .padding(.leading, 16)
                .background(
                    Color(.Background.teritary)
                        .clipShape(
                            .rect(
                                topLeadingRadius: index == 0 ? radius : 0,
                                bottomLeadingRadius: index == allCount - 1 ? radius : 0,
                                bottomTrailingRadius: index == allCount - 1 ? radius : 0,
                                topTrailingRadius: index == 0 ? radius : 0
                            )
                        )
                )
            }
            .listSectionSeparator(.hidden)
            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listRowBackground(Color(.Background.primary))
        }
    }
    
    // MARK: - Merge Button
    
    @ViewBuilder
    private func MergeButton() -> some View {
        Button {
            send(.mergeButtonTapped)
        } label: {
            Text("Merge", bundle: .module)
                .frame(maxWidth: .infinity)
                .padding(8)
            
        }
        .buttonStyle(.borderedProminent)
        .tint(tintColor)
        .frame(height: 48)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(.Background.primary))
    }

    // MARK: - Header
    
    private func Header(title: LocalizedStringKey) -> some View {
        Text(title, bundle: .module)
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(Color(.Labels.teritary))
            .textCase(nil)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func PickerHeader(title: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color(.Labels.primary))
                .padding(.leading, 16)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
            
            Spacer()
            
            Image(systemSymbol: .chevronUpChevronDown)
                .foregroundStyle(Color(.Labels.teritary))
                .padding(.trailing, 11)
        }
        .frame(minHeight: 60)
        .background(Color(.Background.teritary))
        .cornerRadius(isLiquidGlass ? 28 : 14)
    }
}

// MARK: - Previews

#Preview("Merge Topics") {
    NavigationStack {
        ForumMergeView(
            store: Store(
                initialState: ForumMergeFeature.State(
                    type: .topics([.mockLong, .mockToday, .mockTodayUnread])
                )
            ) {
                ForumMergeFeature()
            }
        )
    }
}
