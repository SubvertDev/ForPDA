//
//  AnnouncementFeature.swift
//  ForPDA
//
//  Created by Xialtal on 24.11.24.
//

import Foundation
import ComposableArchitecture
import APIClient
import ParsingClient
import Models
import SharedUI
import PersistenceKeys
import AnalyticsClient
import TopicBuilder
import ToastClient

@Reducer
public struct AnnouncementFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public var announcementId: Int
        public var name: String?
        
        public var announcement: Announcement?
        
        var types: [[UITopicType]] = []
        
        var didLoadOnce = false
       
        public init(id: Int, name: String? = nil) {
            self.announcementId = id
            self.name = name
        }
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction {
        case view(View)
        public enum View {
            case onAppear
            case urlTapped(URL)
        }

        case `internal`(Internal)
        public enum Internal {
            case loadAnnouncement
            case loadTypes([[UITopicType]])
            case announcementResponse(Result<Announcement, any Error>)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case handleUrl(URL)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.toastClient) private var toastClient
    @Dependency(\.analyticsClient) private var analyticsClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                return .send(.internal(.loadAnnouncement))
                
            case .internal(.loadAnnouncement):
                guard state.announcement == nil else { return .none }
                return .run { [id = state.announcementId] send in
                    let result = await Result { try await apiClient.getAnnouncement(id) }
                    await send(.internal(.announcementResponse(result)))
                }
                
            case let .view(.urlTapped(url)):
                return .send(.delegate(.handleUrl(url)))
                   
            case let .internal(.announcementResponse(.success(announcement))):
                // customDump(announcement)
                state.announcement = announcement
                state.name = state.name ?? announcement.name

                return .run { send in
                    var topicTypes: [[UITopicType]] = []
                    
                    let types = TopicNodeBuilder(text: announcement.content, attachments: []).build()
                    topicTypes.append(types)
                    
                    await send(.internal(.loadTypes(topicTypes)))
                }
                
            case let .internal(.loadTypes(types)):
                state.types = types
                reportFullyDisplayed(&state)
                return .none
                
            case .internal(.announcementResponse(.failure)):
                reportFullyDisplayed(&state)
                return .run { _ in await toastClient.showToast(.whoopsSomethingWentWrong) }
                
            case .delegate:
                return .none
            }
        }
        
        Analytics()
    }
    
    // MARK: - Shared Logic
    
    private func reportFullyDisplayed(_ state: inout State) {
        guard !state.didLoadOnce else { return }
        analyticsClient.reportFullyDisplayed()
        state.didLoadOnce = true
    }
}
