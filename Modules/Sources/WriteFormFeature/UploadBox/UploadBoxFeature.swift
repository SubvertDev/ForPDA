//
//  UploadBoxFeature.swift
//  ForPDA
//
//  Created by Xialtal on 19.07.25.
//

import Foundation
import ComposableArchitecture
import APIClient
import Models

@Reducer
public struct UploadBoxFeature: Reducer, Sendable {
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable, Sendable {

//        public init(
//            formType: WriteFormForType
//        ) {
//            self.formType = formType
//        }
    }
    
    // MARK: - Action
            
    public enum Action {
        case onAppear
        
        case cancelButtonTapped
    }
    
    // MARK: - Dependencies
        
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.dismiss) var dismiss
        
    // MARK: - Body
            
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                return .none
                
            case .cancelButtonTapped:
                return .none
            }
        }
    }
}
