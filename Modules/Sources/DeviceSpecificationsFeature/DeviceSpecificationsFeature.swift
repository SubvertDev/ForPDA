//
//  DeviceSpecificationsFeature.swift
//  ForPDA
//
//  Created by Xialtal on 23.12.25.
//

import Foundation
import ComposableArchitecture
import APIClient
import Models

@Reducer
public struct DeviceSpecificationsFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        
        public let tag: String
        public let subTag: String?
        
        var specifications: DeviceSpecificationsResponse?
        
        var isLoading = false
        
        public init(
            tag: String,
            subTag: String?
        ) {
            self.tag = tag
            self.subTag = subTag
        }
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction {
        case view(View)
        public enum View {
            case onAppear
            case loadSpecifications
            
            case editionButtonTapped(String)
        }
        
        case `internal`(Internal)
        public enum Internal {
            case specificationsResponse(DeviceSpecificationsResponse)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case openDevice(tag: String, subTag: String)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                return .send(.view(.loadSpecifications))
                
            case let .view(.editionButtonTapped(subTag)):
                return .send(.delegate(.openDevice(tag: state.tag, subTag: subTag)))
                
            case .view(.loadSpecifications):
                state.isLoading = true
                return .run { [tag = state.tag, subTag = state.subTag] send in
                    let respone = try await apiClient.deviceSpecifications(
                        tag: tag,
                        subTag: subTag ?? ""
                    )
                    await send(.internal(.specificationsResponse(respone)))
                }
                
            case let .internal(.specificationsResponse(response)):
                state.specifications = response
                state.isLoading = false
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
}
