//
//  ListTagBuilderFeature.swift
//  ForPDA
//
//  Created by Xialtal on 2.01.26.
//

import ComposableArchitecture

@Reducer
public struct ListTagBuilderFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public enum Field: Hashable { case item(Int) }
        
        let isBullet: Bool
        
        var focus: Field?
        
        var listItems: [ListItemField] = []
        
        var isAddItemButtonDisabled: Bool {
            for item in listItems {
                if item.content.isEmpty {
                    return true
                }
            }
            return false
        }
        
        public init(
            isBullet: Bool
        ) {
            self.isBullet = isBullet
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        
        case view(View)
        public enum View {
            case onAppear
            case createButtonTapped
            case cancelButtonTapped
            
            case addListItemButtonTapped
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case listTagBuilded((String, String))
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.dismiss) private var dismiss
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                state.listItems.append(.init(id: 0, content: ""))
                state.focus = .item(0)
                return .none
                
            case .view(.addListItemButtonTapped):
                let newId = state.listItems.count
                state.listItems.append(.init(id: newId, content: ""))
                state.focus = .item(newId)
                return .none
                
            case .view(.createButtonTapped):
                var leftTag = "[LIST\(!state.isBullet ? "=1" : "")]"
                for item in state.listItems {
                    if item != state.listItems.first {
                        leftTag.append("\n")
                    }
                    leftTag.append("[*]\(item.content)")
                }
                return .send(.delegate(.listTagBuilded((leftTag, "[/LIST]"))))
                
            case .view(.cancelButtonTapped), .delegate(.listTagBuilded):
                return .run { _ in await dismiss() }
                
            case .delegate, .binding:
                return .none
            }
        }
    }
}
