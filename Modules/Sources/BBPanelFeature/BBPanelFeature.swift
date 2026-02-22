//
//  BBPanelFeature.swift
//  ForPDA
//
//  Created by Xialtal on 28.12.25.
//

import Foundation
import ComposableArchitecture
import UploadBoxFeature

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
        case colorTag
        
        case urlTag
        case spoilerWithTitleTag
        
        case listTag(ListTagBuilderFeature)
    }
    
    // MARK: - View State
    
    public enum BBPanelViewState {
        case tags
        case colorPicker
        case fontSizePicker
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Presents var destination: Destination.State?
        
        var upload = UploadBoxFeature.State(
            type: .bbPanel,
            allowedExtensions: []
        )
        
        let panelWith: BBPanelType
        let supportsUpload: Bool
        
        var tags: [BBPanelTag] = []
        var viewState: BBPanelViewState = .tags
        
        var alertInput = ""
        var textSize = 1
        
        var isUploading = false
        var uploadedFiles = 0
        var showUploadBox = false
        
        public init(
            for panelType: BBPanelType,
            supportsUpload: Bool = false
        ) {
            self.panelWith = panelType
            self.supportsUpload = supportsUpload
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        case destination(PresentationAction<Destination.Action>)
        case upload(UploadBoxFeature.Action)
        
        case view(View)
        public enum View {
            case onAppear
            case tagButtonTapped(BBPanelTag)
            case alertTagButtonTapped(BBPanelTag)
            case hideUploadBoxButtonTapped
            case returnTagsButtonTapped
            
            case colorSelected(String)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case tagTapped((String, String))
        }
    }
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Scope(state: \.upload, action: \.upload) {
            UploadBoxFeature()
        }
        
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                var tags = state.panelWith.kit
                if state.supportsUpload {
                    tags.insert(.upload, at: 0)
                }
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
                    print("SIMPLE Tag tapped: \(tag)")
                    return .send(.delegate(.tagTapped(("[\(tag.code)]", "[/\(tag.code)]"))))
                case .size:
                    //state.destination = .sizeTag
                    state.viewState = .fontSizePicker
                case .color:
                    //state.destination = .colorTag
                    state.viewState = .colorPicker
                case .url:
                    state.destination = .urlTag
                case .spoilerWithTitle:
                    state.destination = .spoilerWithTitleTag
                case .listNumber:
                    state.destination = .listTag(ListTagBuilderFeature.State(isBullet: false))
                case .listBullet:
                    state.destination = .listTag(ListTagBuilderFeature.State(isBullet: true))
                case .upload:
                    state.showUploadBox.toggle()
                }
                return .none
                
            case .view(.returnTagsButtonTapped):
                state.viewState = .tags
                return .none
                
            case let .view(.colorSelected(color)):
                state.destination = nil
                return .send(.delegate(.tagTapped(("[COLOR=\(color)]", "[/COLOR]"))))
                
            case let .view(.alertTagButtonTapped(tag)):
                let input = state.alertInput
                state.alertInput = ""
                return .send(.delegate(.tagTapped(("[\(tag.code)=\(input)]", "[/\(tag.code)]"))))
                
            case .view(.hideUploadBoxButtonTapped):
                state.showUploadBox = false
                return .none
                
            case let .destination(.presented(.listTag(.delegate(.listTagBuilded(tag))))):
                return .send(.delegate(.tagTapped(tag)))
                
            case .upload(.delegate(.someFileUploading)):
                state.isUploading = true
                return .none
                
            case .upload(.delegate(.allFilesAreUploaded)):
                state.isUploading = false
                return .none
                
            case .delegate, .destination, .binding, .upload:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension BBPanelFeature.Destination.State: Equatable {}
