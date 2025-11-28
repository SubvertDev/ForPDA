//
//  SearchScreen.swift
//  ForPDA
//
//  Created by Рустам Ойтов on 17.08.2025.
//

import SwiftUI
import SharedUI
import ComposableArchitecture
import Models

@ViewAction(for: SearchFeature.self)
public struct SearchScreen: View {
    
    @Perception.Bindable public var store: StoreOf<SearchFeature>
    @Environment(\.tintColor) private var tintColor
    
    @FocusState public var focus: SearchFeature.State.Field?
    
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
                
                List {
                    ParametersSection()
                    
                    if !additionalHidden {
                        AuthorSection()
                        
                        if store.shouldShowAuthorsList {
                            AuthorsList()
                        }
                    }
                    
                    ShowParametersButton()
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(Text("Search", bundle: .module))
            .background(Color(.Background.primary))
            .searchable(text: $store.searchText)
            .onSubmit(of: .search) {
                send(.startSearch)
            }
            .bind($store.focus, to: $focus)
            .onAppear {
                send(.onAppear)
            }
        }
    }
    
    @ViewBuilder
    private func ParametersSection() -> some View {
        Section {
            WhereSearch()
            
            if !additionalHidden {
                SortSearch()
                
                if store.whereSearch != .site {
                    if store.whereSearch != .topic {
                        ResultAsTopicsRow()
                    }
                    
                    SearchOnForum()
                }
            }
        }
        .listRowBackground(Color(.Background.teritary))
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
    
    @ViewBuilder
    private func WhereSearch() -> some View {
        Picker(
            LocalizedStringResource("Where", bundle: .module),
            selection: $store.whereSearch
        ) {
            Text(SearchWhere.site.title, bundle: .module)
                .tag(SearchWhere.site)
            
            Text(SearchWhere.forum.title, bundle: .module)
                .tag(SearchWhere.forum)
            
            Text(SearchWhere.topic.title, bundle: .module)
                .tag(SearchWhere.topic)
            
            if let forum = store.navigation.last, !forum.isCategory {
                Text("On \(forum.name)", bundle: .module)
                    .tag(SearchWhere.custom)
            }
        }
        .padding(12)
        .frame(height: 60)
        .cornerRadius(10)
    }
    
    @ViewBuilder
    private func SortSearch() -> some View {
        Picker(
            LocalizedStringResource("Sort", bundle: .module),
            selection: $store.searchSort
        ) {
            Text(SearchSort.relevance.title, bundle: .module)
                .tag(SearchSort.relevance)
            
            Text(SearchSort.dateAscSort.title, bundle: .module)
                .tag(SearchSort.dateAscSort)
            
            Text(SearchSort.dateDescSort.title, bundle: .module)
                .tag(SearchSort.dateDescSort)
        }
        .padding(12)
        .frame(height: 60)
        .cornerRadius(10)
    }
    
    @ViewBuilder
    private func ResultAsTopicsRow() -> some View {
        HStack(spacing: 0) {
            Text("Result as topics", bundle: .module)
                .foregroundStyle(.primary)
                .font(.body)
                .padding(.leading, 16)
                .padding(.vertical, 19)
            
            Spacer()
            
            Toggle(isOn: $store.searchResultsAsTopics) {}
                .padding(.trailing, 16)
        }
    }
    
    // MARK: - Search on Forum Picker
    
    @ViewBuilder
    private func SearchOnForum() -> some View {
        Picker(
            LocalizedStringResource("Search on forum", bundle: .module),
            selection: $store.forumSearchIn
        ) {
            Text(ForumSearchIn.all.title, bundle: .module)
                .tag(ForumSearchIn.all)
            
            Text(ForumSearchIn.posts.title, bundle: .module)
                .tag(ForumSearchIn.posts)
            
            Text(ForumSearchIn.titles.title, bundle: .module)
                .tag(ForumSearchIn.titles)
        }
        .padding(12)
        .frame(minHeight: 60)
        .cornerRadius(10)
    }
    
    // MARK: - Author Section
    
    private func AuthorSection() -> some View {
        Section {
            SharedUI.ForField(
                content: $store.authorName,
                placeholder: LocalizedStringResource("Input...", bundle: .module),
                focusEqual: SearchFeature.State.Field.authorName,
                focus: $focus,
                characterLimit: 26
            )
            .overlay(alignment: .trailing) {
                if store.isAuthorsLoading {
                    ProgressView()
                        .frame(width: 22, height: 22)
                        .padding(.horizontal, 12)
                } else if store.authorId != nil {
                    AuthorProfileLinkButton()
                }
            }
            .onChange(of: store.authorName) { name in
                if !name.isEmpty, name.count >= 3 {
                    send(.searchAuthorName(name))
                }
            }
        } header: {
            Text("Author nickname", bundle: .module)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(Color(.Labels.teritary))
                .textCase(nil)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onTapGesture {
            focus = nil
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
    
    private func AuthorProfileLinkButton() -> some View {
        Button {
            send(.authorProfileButtonTapped)
        } label: {
            HStack(spacing: 0) {
                Text("Profile", bundle: .module)
                    .font(.caption)
                    .foregroundStyle(Color(.Labels.teritary))
                
                Image(systemSymbol: .arrowUpRight)
                    .frame(width: 32, height: 32)
                    .foregroundStyle(tintColor)
            }
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }
    
    private func AuthorsList() -> some View {
        Section {
            ForEach(store.authors) { author in
                Button {
                    send(.selectUser(author.id, author.name))
                } label: {
                    HStack {
                        Text(author.name)
                            .foregroundStyle(Color(.Labels.primary))
                            .font(.body)
                            .lineLimit(1)
                            .padding(.horizontal, 28)
                        
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.Background.teritary))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 0)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
    
    // MARK: - Show Parameters Button
    
    @ViewBuilder
    private func ShowParametersButton() -> some View {
        Button {
            withAnimation(.easeInOut) {
                additionalHidden.toggle()
            }
        } label: {
            HStack(spacing: 0) {
                Text(additionalHidden ? "More parameters" : "Fewer parameters", bundle: .module)
                    .foregroundStyle(Color(.Labels.teritary))
                    .font(.callout)
                    .padding(.trailing, 8)
                
                Image(systemSymbol: .chevronDown)
                    .foregroundStyle(Color(.Labels.teritary))
                    .font(.body)
                    .rotationEffect(.degrees(additionalHidden ? 0 : -180))
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - Preview

#Preview {
    SearchScreen(
        store: Store(
            initialState: SearchFeature.State(
                on: .site,
                navigation: [.mock]
            ),
        ) {
            SearchFeature()
        }
    )
}
