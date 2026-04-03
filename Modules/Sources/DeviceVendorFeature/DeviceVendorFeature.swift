//
//  DeviceVendorFeature.swift
//  ForPDA
//
//  Created by Xialtal on 2.04.26.
//

import Foundation
import ComposableArchitecture
import APIClient
import Models
import ToastClient

@Reducer
public struct DeviceVendorFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - Category
    
    public enum CategorySelection: Int, Equatable {
        case all
        case actual
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public let type: DeviceType
        public let vendorName: String
        
        var vendor: DeviceVendor?
        var categorySelection: CategorySelection = .actual
        
        var isLoading = false
        
        public init(
            type: DeviceType,
            vendorName: String
        ) {
            self.type = type
            self.vendorName = vendorName
        }
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction {
        case view(View)
        public enum View {
            case onAppear
            case productButtonTapped(String)
            case changeCategoryButtonTapped(CategorySelection)
        }
        
        case `internal`(Internal)
        public enum Internal {
            case loadVendor
            case vendorResponse(Result<DeviceVendor, any Error>)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case openDevice(tag: String)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.openURL) var openURL
    @Dependency(\.toastClient) var toastClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                return .send(.internal(.loadVendor))
                
            case let .view(.productButtonTapped(tag)):
                return .send(.delegate(.deviceTapped(tag: tag)))
                
            case let .view(.changeCategoryButtonTapped(category)):
                state.categorySelection = category
                return .none
                
            case .internal(.loadVendor):
                state.isLoading = true
                return .run { [name = state.vendorName, type = state.type] send in
                    let response = try await apiClient.deviceVendor(name: name, type: type)
                    await send(.internal(.vendorResponse(.success(response))))
                } catch: { error, send in
                    await send(.internal(.vendorResponse(.failure(error))))
                }
                
            case let .internal(.vendorResponse(.success(response))):
                state.vendor = response
                state.isLoading = false
                return .none
                
            case let .internal(.vendorResponse(.failure(error))):
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
