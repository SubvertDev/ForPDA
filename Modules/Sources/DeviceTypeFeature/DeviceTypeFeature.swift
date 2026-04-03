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
public struct DeviceTypeFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - Category
    
    public enum CategorySelection: Int, Equatable {
        case all
        case actual
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public let content: DeviceTypeContent
        
        var vendor: DeviceVendor?
        var vendorsList: DeviceVendorsList?
        
        var categorySelection: CategorySelection = .actual
        var isLoading = false
        
        public init(
            content: DeviceTypeContent
        ) {
            self.content = content
        }
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction {
        case view(View)
        public enum View {
            case onAppear
            case productButtonTapped(String)
            case typeButtonTapped(DeviceType)
            case vendorButtonTapped(String, DeviceType)
            case changeCategoryButtonTapped(CategorySelection)
        }
        
        case `internal`(Internal)
        public enum Internal {
            case loadVendorsList(DeviceType)
            case vendorsListResponse(Result<DeviceVendorsList, any Error>)
            
            case loadVendor(String, DeviceType)
            case vendorResponse(Result<DeviceVendor, any Error>)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case openVendorsList(DeviceType)
            case openDevice(tag: String)
            case openVendor(String, DeviceType)
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
                switch state.content {
                case .vendorsList(let type):
                    return .send(.internal(.loadVendorsList(type)))
                case .vendor(let name, let type):
                    return .send(.internal(.loadVendor(name, type)))
                case .index:
                    break
                }
                return .none
                
            case let .view(.productButtonTapped(tag)):
                return .send(.delegate(.openDevice(tag: tag)))
                
            case let .view(.typeButtonTapped(type)):
                return .send(.delegate(.openVendorsList(type)))
                
            case let .view(.vendorButtonTapped(name, type)):
                return .send(.delegate(.openVendor(name, type)))
                
            case let .view(.changeCategoryButtonTapped(category)):
                state.categorySelection = category
                return .none
                
            case let .internal(.loadVendorsList(type)):
                state.isLoading = true
                return .run { send in
                    let response = try await apiClient.deviceBrands(type: type)
                    await send(.internal(.vendorsListResponse(.success(response))))
                } catch: { error, send in
                    await send(.internal(.vendorsListResponse(.failure(error))))
                }
                
            case let .internal(.vendorsListResponse(.success(response))):
                state.vendorsList = response
                state.isLoading = false
                return .none
                
            case let .internal(.loadVendor(name, type)):
                state.isLoading = true
                return .run { send in
                    let response = try await apiClient.deviceVendor(name: name, type: type)
                    await send(.internal(.vendorResponse(.success(response))))
                } catch: { error, send in
                    await send(.internal(.vendorResponse(.failure(error))))
                }
                
            case let .internal(.vendorResponse(.success(response))):
                state.vendor = response
                state.isLoading = false
                return .none
                
            case .internal(.vendorResponse(.failure(let error))),
                 .internal(.vendorsListResponse(.failure(let error))):
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
