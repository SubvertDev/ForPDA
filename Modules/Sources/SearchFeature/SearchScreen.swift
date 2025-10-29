//
//  SearchScreen.swift
//  ForPDA
//
//  Created by Рустам Ойтов on 17.08.2025.
//

import SwiftUI
import SharedUI
import ComposableArchitecture

@ViewAction(for: SearchFeature.self)
public struct SearchScreen: View {
    @Perception.Bindable public var store: StoreOf<SearchFeature>
    @State private var additionalHidden = true
    
    public init(store: StoreOf<SearchFeature>) {
        self.store = store
    }
    
    // MARK: - body
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                NavigationStack {
                    ScrollView {
                        VStack(spacing: 0) {
                            RowFilters(
                                name: "Search",
                                values: [
                                    "Everywhere",
                                    "On the forum",
                                    "On the site"
                                ],
                                selectedValue: $store.whereSearch
                            )
                            .padding(.horizontal, 16)
                            
                            if !additionalHidden {
                                additionalFilters()
                                
                                if store.showMembers {
                                    ForEach(store.members, id: \.id) { member in
                                        memberRow(id: member.id, name: member.nickname)
                                    }
                                }
                            }
                            showParametersButton()
                        }
                    }
                    .background(Color(.Background.primary))
                    .navigationTitle("Search")
                    .searchable(text: $store.searchText)
                    .onSubmit(of: .search) {
                        send(.startSearch)
                    }
                    
                }
            }
        }
    }
    
    // MARK: - row filters
    
    @ViewBuilder
    private func RowFilters(name: String, values: [String], selectedValue: Binding<String>) -> some View {
        if name == "Nickname" {
            authorNicknameFilter()
        } else if values.isEmpty {
            viewTopicFilter(name: name)
        } else {
            menuFilter(name: name, values: values, selectedValue: selectedValue)
        }
    }
    
    // MARK: - author nickname filter
    
    @ViewBuilder
    private func authorNicknameFilter() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Nickname author")
                .foregroundStyle(Color(.Labels.teritary))
                .font(.footnote)
                .fontWeight(.semibold)
                .padding(.bottom, 6)
            
            HStack(spacing: 0) {
                TextField("Input...", text: $store.nicknameAuthor)
                    .padding(.horizontal, 12)
                    .textFieldStyle(.plain)
                    .frame(height: 52)
                    .background(Color(.Background.teritary))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(.Separator.primary), lineWidth: 0.33)
                    )
                    .onChange(of: store.nicknameAuthor) { text in
                        send(.searchAuthorName(text))
                    }
            }
        }
        .padding(.bottom, 11)
    }
    
    // MARK: - view topic filter
    
    @ViewBuilder
    private func viewTopicFilter(name: String) -> some View {
        HStack(spacing: 0) {
            Text(name)
                .foregroundStyle(.primary)
                .font(.body)
                .padding(.leading, 16)
                .padding(.vertical, 19)
            
            Spacer()
            
            Toggle(isOn: $store.toggleRes) {}
                .padding(.trailing, 16)
        }
        .background(Color(.Background.teritary))
    }
    
    // MARK: - additional filters
    
    @ViewBuilder
    private func additionalFilters() -> some View {
        Group {
            RowFilters(
                name: "Sort",
                values: [
                    "Relevance(matching the query)",
                    "Date (newest to oldest)",
                    "Date (oldest to newest)"
                ],
                selectedValue: $store.sortBy
            )
            
            RowFilters(
                name: "Result in view topic",
                values: [],
                selectedValue: .constant("")
            )
            
            RowFilters(
                name: "Search the forum",
                values: [
                    "Everywhere",
                    "In posts",
                    "In titles"
                ],
                selectedValue: $store.whereSerchForum
            )
            .padding(.bottom, 28)
            
            RowFilters(
                name: "Nickname",
                values: [],
                selectedValue: .constant("")
            )
        }
        .padding(.horizontal, 16)
        .transition(.opacity)
    }
    
    // MARK: - menu filter
    
    @ViewBuilder
    private func menuFilter(name: String, values: [String], selectedValue: Binding<String>) -> some View {
        HStack(spacing: 0) {
            Text(name)
                .foregroundStyle(.primary)
                .font(.body)
                .padding(.leading, 16)
                .padding(.vertical, 19)
            
            Spacer()
            
            Menu {
                ForEach(values, id: \.self) { value in
                    Button {
                        selectedValue.wrappedValue = value
                        print("\(value) tapped")
                    } label: {
                        HStack {
                            Text(value)
                            if selectedValue.wrappedValue == value {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Text(selectedValue.wrappedValue)
                    .foregroundStyle(Color(.Labels.quaternary))
                
                Image(systemName: "chevron.compact.up.chevron.compact.down")
                    .foregroundStyle(Color(.Labels.quaternary))
                    .padding(.trailing, 16)
            }
        }
        .background(Color(.Background.teritary))
    }
    
    // MARK: - member row
    
    @ViewBuilder
    private func memberRow(id: Int, name: String) -> some View {
        Button {
            print("user \(id) was tapped")
            send(.selectUser(id, name))
        } label: {
            HStack {
                Text(name)
                    .foregroundStyle(Color(.Labels.primary))
                    .font(.body)
                    .lineLimit(1)
                    .padding(.horizontal, 28)
                
                Spacer()
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.Background.teritary))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }
    
    // MARK: - show parameters button
    
    @ViewBuilder
    private func showParametersButton() -> some View {
        Button {
            withAnimation(.easeInOut) {
                additionalHidden.toggle()
            }
        } label: {
            HStack(spacing: 0) {
                Text(additionalHidden ? "More parameters" : "Fewer parameters")
                    .foregroundStyle(Color(.Labels.teritary))
                    .font(.callout)
                    .padding(.trailing, 8)
                
                Image(systemSymbol: .chevronDown)
                    .foregroundStyle(Color(.Labels.teritary))
                    .font(.body)
                    .rotationEffect(.degrees(additionalHidden ? 0 : -180))
            }
            .padding(.top, additionalHidden ? 28 : 16)
        }
    }
}

// MARK: - Preview

#Preview {
    SearchScreen(
        store: Store(
            initialState: SearchFeature.State(),
        ) {
            SearchFeature()
        }
    )
}
