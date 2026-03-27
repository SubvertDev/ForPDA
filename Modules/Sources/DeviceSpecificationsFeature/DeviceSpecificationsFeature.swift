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
import ToastClient

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
            
            case editionButtonTapped(String)
        }
        
        case `internal`(Internal)
        public enum Internal {
            case loadSpecifications
            case specificationsResponse(Result<DeviceSpecificationsResponse, any Error>)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case openDevice(tag: String, subTag: String)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.toastClient) private var toastClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                return .send(.internal(.loadSpecifications))
                
            case let .view(.editionButtonTapped(subTag)):
                return .send(.delegate(.openDevice(tag: state.tag, subTag: subTag)))
                
            case let .view(.markAsMyDeviceButtonTapped(myDevice)):
                return .none
                
            case .internal(.loadSpecifications):
                state.isLoading = true
                return .run { [tag = state.tag, subTag = state.subTag] send in
                    let respone = try await apiClient.deviceSpecifications(
                        tag: tag,
                        subTag: subTag ?? ""
                    )
                    await send(.internal(.specificationsResponse(.success(respone))))
                } catch: { error, send in
                    await send(.internal(.specificationsResponse(.failure(error))))
                }
                
            case let .internal(.specificationsResponse(.success(response))):
                state.specifications = response
                state.isLoading = false
                return .none
                
            case let .internal(.specificationsResponse(.failure(error))):
                print(error)
                state.isLoading = false
                return .run { _ in
                    await toastClient.showToast(.whoopsSomethingWentWrong)
                }
                
            case .delegate:
                return .none
            }
        }
    }
}
