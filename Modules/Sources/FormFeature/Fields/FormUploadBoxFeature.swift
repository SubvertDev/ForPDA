//
//  FormUploadBoxFeature.swift
//  FormFeature
//
//  Created by Ilia Lubianoi on 19.07.2025.
//

import SwiftUI
import ComposableArchitecture
import UploadBoxFeature

// MARK: - Feature

@Reducer
public struct FormUploadBoxFeature: Reducer {
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable, FormFieldConformable {
        public var upload = UploadBoxFeature.State(type: .form)
        
        public let id: Int
        let title: String
        let description: String
        let flag: Int
        let allowedExtensions: [String]
        
        var isLoading: Bool
        var uploadedFilesIds: [Int] = []
        
        public init(
            id: Int,
            title: String,
            description: String,
            flag: Int,
            allowedExtensions: [String],
            isLoading: Bool = false
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.flag = flag
            self.allowedExtensions = allowedExtensions
            self.isLoading = isLoading
        }
        
        func getValue() -> FormValue {
            return .array(uploadedFilesIds.map { .integer($0) })
        }
        
        func isValid() -> Bool {
            if isLoading { return false }
            return isRequired ? !uploadedFilesIds.isEmpty : true
        }
    }
    
    // MARK: - Actions
    
    public enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        case upload(UploadBoxFeature.Action)

        case view(View)
        public enum View {
            case onAppear
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
            case .upload(.delegate(.someFileUploading)):
                state.isLoading = true
                
            case .upload(.delegate(.allFilesAreUploaded)):
                state.isLoading = false
                
            case let .upload(.delegate(.fileHasBeenUploaded(id))):
                state.uploadedFilesIds.append(id)
                
            case let .upload(.delegate(.fileHasBeenRemoved(id))):
                state.uploadedFilesIds.removeAll(where: { $0 == id })
                
            case .view(.onAppear):
                state.upload.allowedExtensions = state.allowedExtensions
                
            case .binding, .upload:
                break
            }
            return .none
        }
    }
}

// MARK: - View

@ViewAction(for: FormUploadBoxFeature.self)
struct FormUploadBoxRow: View {
    
    // MARK: - Properties
    
    @Perception.Bindable var store: StoreOf<FormUploadBoxFeature>
    @Environment(\.tintColor) private var tintColor
    
    // MARK: - Body
    
    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 6) {
                FieldSection(
                    title: store.title,
                    description: store.description,
                    required: store.isRequired
                ) {
                    WithPerceptionTracking {
                        UploadBoxView(store: store.scope(state: \.upload, action: \.upload))
                    }
                }
            }
            .tint(tintColor)
            .onAppear {
                send(.onAppear)
            }
        }
    }
}

// MARK: - Previews

#Preview("Upload Box (Empty)") {
    FormUploadBoxRow(
        store: Store(
            initialState: FormUploadBoxFeature.State(
                id: 0,
                title: "File skin",
                description: "Supported formats: jpg, jpeg, gif, png",
                flag: 1,
                allowedExtensions: ["jpg", "jpeg", "gif", "png"]
            )
        ) {
            FormUploadBoxFeature()
        }
    )
    .padding(.horizontal, 16)
    .environment(\.tintColor, Color(.Theme.primary))
}
