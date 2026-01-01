//
//  BBPanelFeature.swift
//  ForPDA
//
//  Created by Xialtal on 28.12.25.
//

import SwiftUI
import Foundation
import ComposableArchitecture

@Reducer
public struct BBPanelFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - Localizations
    
    public enum Localization {
        static let inputFullUrl = LocalizedStringResource("Input full URL-address", bundle: .module)
        static let inputSpoilerTitle = LocalizedStringResource("Input spoiler title", bundle: .module)
    }
    
    // MARK: - Destinations
    
    @Reducer
    public enum Destination {
        case sizeTag
        case listTag
        case colorTag
        case smileTag
        
        case urlTag
        case spoilerWithTitleTag
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Presents var destination: Destination.State?
        
        let panelWith: BBPanelType
        
        var tags: [BBPanelTag] = []
        
        var alertInput = ""
        
        public init(
            with: BBPanelType
        ) {
            self.panelWith = with
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        case destination(PresentationAction<Destination.Action>)
        
        case view(View)
        public enum View {
            case onAppear
            case tagButtonTapped(BBPanelTag)
            
            case alertTagButtonTapped(BBPanelTag)
            
            case colorSelected(String)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case tagTapped((String, String))
            case smileTapped(String)
        }
    }
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                var tags = state.panelWith.kit
                if case let .post(isCurator, canModerate) = state.panelWith {
                    if canModerate {
                        tags.append(.cur)
                        tags.append(.mod)
                        tags.append(.ex)
                    } else if isCurator {
                        tags.append(.cur)
                    }
                }
                state.tags = tags
                return .none
                
            case let .view(.tagButtonTapped(tag)):
                switch tag {
                case .b, .i, .s, .u, .sup, .sub, .offtop, .center, .left, .right, .hide, .code, .cur, .mod, .ex, .quote, .spoiler:
                    return .send(.delegate(.tagTapped(("[\(tag.code)]", "[/\(tag.code)]"))))
                case .size:
                    return .none
                case .color:
                    state.destination = .colorTag
                case .url:
                    state.destination = .urlTag
                case .listNumber:
                    return .none
                case .listBullet:
                    return .none
                case .upload:
                    // TODO: Attachments...
                    return .none
                case .spoilerWithTitle:
                    state.destination = .spoilerWithTitleTag
                case .smile:
                    state.destination = .smileTag
                }
                return .none
                
            case let .view(.colorSelected(color)):
                state.destination = nil
                return .send(.delegate(.tagTapped(("[COLOR=\(color)]", "[/COLOR]"))))
                
            case let .view(.alertTagButtonTapped(tag)):
                let input = state.alertInput
                state.alertInput = ""
                return .send(.delegate(.tagTapped(("[\(tag.code)=\(input)]", "[/\(tag.code)]"))))
                
            case .delegate, .destination, .binding:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension BBPanelFeature.Destination.State: Equatable {}
