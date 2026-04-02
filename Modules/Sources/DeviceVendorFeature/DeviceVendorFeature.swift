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

@Reducer
public struct DeviceVendorFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public let type: DeviceType
        public let vendorName: String
        
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
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.openURL) var openURL
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                return .none
            }
        }
    }
}
